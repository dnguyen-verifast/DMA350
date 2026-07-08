//==============================================================================
// crlp_driver.svh
//   Drives clock, reset, static clock-enables, and the Q-Channel / P-Channel
//   low-power handshakes into the DMAC.
//
//   Clock engine:
//     A free-running background process toggles vif.clk.  It can be gated
//     (clk_enabled=0) either by bench control (OP_CLK_STOP) or, more
//     realistically, once a Q-Channel quiescence request is ACCEPTED.
//     Handshakes are always performed with the clock running.
//==============================================================================
`ifndef CRLP_DRIVER_SVH
`define CRLP_DRIVER_SVH

class crlp_driver extends uvm_driver #(crlp_seq_item);
  `uvm_component_utils(crlp_driver)

  crlp_config      cfg;
  virtual crlp_if  vif;

  // Clock-engine control
  protected bit    clk_enabled = 0;   // 1 -> clock toggles
  protected time   half_period;

  // Current Q-Channel state (as driven by this controller)
  protected crlp_qch_state_e qstate = Q_STOPPED;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  //--------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(crlp_config)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "crlp_config not set in config_db")
    vif         = cfg.vif;
    half_period = cfg.half_period();
  endfunction

  //--------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    // Drive safe initial values before any clock edge.
    init_signals();

    // Background clock engine.
    fork
      clock_engine();
    join_none

    // Optionally bring the clock up automatically.
    if (cfg.auto_start_clock) begin
      qstate      = Q_RUN;
      clk_enabled = 1;
    end

    // Main item loop.
    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  //--------------------------------------------------------------------------
  protected task init_signals();
    vif.clk       = 1'b0;
    vif.resetn    = 1'b0;             // start in reset
    vif.aclken_m0 = cfg.init_aclken_m0;
    vif.aclken_m1 = cfg.init_aclken_m1;
    vif.pclken    = cfg.init_pclken;
    vif.clk_qreqn = 1'b1;            // Q_RUN default (no quiescence request)
    vif.preq      = 1'b0;
    vif.pstate    = PSTATE_ON_FULL;
  endtask

  //--------------------------------------------------------------------------
  // Free-running / gateable clock generator.
  //--------------------------------------------------------------------------
  protected task clock_engine();
    forever begin
      if (!clk_enabled) begin
        vif.clk = 1'b0;
        wait (clk_enabled);
      end
      else begin
        #(half_period) vif.clk = ~vif.clk;
      end
    end
  endtask

  //--------------------------------------------------------------------------
  protected task drive_item(crlp_seq_item item);
    case (item.op)
      OP_CLK_START  : do_clk_start(item);
      OP_CLK_STOP   : do_clk_stop(item);
      OP_RESET      : do_reset(item);
      OP_SET_CLKEN  : do_set_clken(item);
      OP_QCH_QUIESCE: do_qch_quiesce(item);
      OP_QCH_WAKE   : do_qch_wake(item);
      OP_PCH_REQ    : do_pch_req(item);
      default       : `uvm_error(get_type_name(),
                        $sformatf("Unknown op %0d", item.op))
    endcase
  endtask

  //==========================================================================
  // Clock control
  //==========================================================================
  protected task do_clk_start(crlp_seq_item item);
    if (item.clk_period_ps != 0) half_period = item.clk_period_ps / 2;
    clk_enabled = 1;
    `uvm_info(get_type_name(),
      $sformatf("Clock started (period=%0t)", 2*half_period), UVM_MEDIUM)
  endtask

  protected task do_clk_stop(crlp_seq_item item);
    clk_enabled = 0;
    `uvm_info(get_type_name(), "Clock force-stopped (bench)", UVM_MEDIUM)
  endtask

  //==========================================================================
  // Reset : LOW asynchronous, HIGH synchronous (spec A-1)
  //==========================================================================
  protected task do_reset(crlp_seq_item item);
    int unsigned n = (item.reset_cycles != 0) ? item.reset_cycles
                                              : cfg.reset_assert_cycles;
    if (!clk_enabled) begin
      clk_enabled = 1;                 // reset deassert needs a running clock
      `uvm_info(get_type_name(), "Auto-starting clock for reset", UVM_LOW)
    end
    // Assert asynchronously.
    vif.resetn <= 1'b0;
    #1ps;
    repeat (n) @(posedge vif.clk);
    // Deassert synchronously: change on negedge so it is stable and clean at
    // the following posedge (avoids recovery/removal ambiguity).
    @(negedge vif.clk);
    vif.resetn <= 1'b1;
    @(posedge vif.clk);
    qstate = Q_RUN;
    `uvm_info(get_type_name(),
      $sformatf("Reset applied for %0d cycles", n), UVM_MEDIUM)
  endtask

  //==========================================================================
  // Static clock enables
  //==========================================================================
  protected task do_set_clken(crlp_seq_item item);
    @(vif.drv_cb);
    vif.aclken_m0 <= item.aclken_m0;
    vif.aclken_m1 <= item.aclken_m1;
    vif.pclken    <= item.pclken;
    `uvm_info(get_type_name(),
      $sformatf("clken set m0=%0b m1=%0b p=%0b",
                item.aclken_m0, item.aclken_m1, item.pclken), UVM_HIGH)
  endtask

  //==========================================================================
  // Q-Channel : request clock quiescence  (Q_RUN -> Q_REQUEST -> ...)
  //==========================================================================
  protected task do_qch_quiesce(crlp_seq_item item);
    int unsigned cyc = 0;
    bit done = 0;

    if (qstate != Q_RUN) begin
      `uvm_warning(get_type_name(),
        $sformatf("QUIESCE requested while not in Q_RUN (%s)", qstate.name()))
    end

    // Q_RUN -> Q_REQUEST
    @(vif.drv_cb);
    vif.drv_cb.clk_qreqn <= 1'b0;
    qstate = Q_REQUEST;

    // Await accept (qacceptn=0, qdeny=0) or deny (qacceptn=1, qdeny=1).
    while (!done && cyc < cfg.qch_timeout_cycles) begin
      @(vif.drv_cb);
      cyc++;
      if (vif.drv_cb.clk_qacceptn === 1'b0 && vif.drv_cb.clk_qdeny === 1'b0) begin
        qstate     = Q_STOPPED;
        item.rsp   = RSP_ACCEPT;
        done       = 1;
        clk_enabled = 0;              // gate the clock : quiescence granted
        `uvm_info(get_type_name(),
          "Q-Channel quiescence ACCEPTED -> clock gated", UVM_MEDIUM)
      end
      else if (vif.drv_cb.clk_qdeny === 1'b1) begin
        qstate   = Q_DENY;
        item.rsp = RSP_DENY;
        done     = 1;
        // Q_DENY -> Q_CONTINUE -> Q_RUN
        vif.drv_cb.clk_qreqn <= 1'b1;
        qstate = Q_CONTINUE;
        do @(vif.drv_cb); while (vif.drv_cb.clk_qdeny !== 1'b0);
        qstate = Q_RUN;
        `uvm_info(get_type_name(),
          "Q-Channel quiescence DENIED -> returned to Q_RUN", UVM_MEDIUM)
      end
    end

    if (!done) begin
      item.rsp = RSP_TIMEOUT;
      vif.drv_cb.clk_qreqn <= 1'b1;    // abort request
      qstate = Q_RUN;
      `uvm_error(get_type_name(), "Q-Channel quiescence TIMEOUT")
    end
    item.latency_cy = cyc;
  endtask

  //==========================================================================
  // Q-Channel : wake / exit quiescence (Q_STOPPED -> Q_EXIT -> Q_RUN)
  //==========================================================================
  protected task do_qch_wake(crlp_seq_item item);
    int unsigned cyc = 0;

    if (qstate != Q_STOPPED) begin
      `uvm_warning(get_type_name(),
        $sformatf("WAKE requested while not Q_STOPPED (%s)", qstate.name()))
    end

    // Restart the clock so the exit handshake can proceed.
    clk_enabled = 1;
    // qreqn may be raised asynchronously; align to a clock for cleanliness.
    @(vif.drv_cb);
    vif.drv_cb.clk_qreqn <= 1'b1;
    qstate = Q_EXIT;

    // Wait for the device to raise qacceptn (back to Q_RUN).
    do begin
      @(vif.drv_cb);
      cyc++;
    end while (vif.drv_cb.clk_qacceptn !== 1'b1 && cyc < cfg.qch_timeout_cycles);

    if (vif.drv_cb.clk_qacceptn === 1'b1) begin
      qstate   = Q_RUN;
      item.rsp = RSP_ACCEPT;
      `uvm_info(get_type_name(), "Q-Channel wake complete -> Q_RUN", UVM_MEDIUM)
    end
    else begin
      item.rsp = RSP_TIMEOUT;
      `uvm_error(get_type_name(), "Q-Channel wake TIMEOUT")
    end
    item.latency_cy = cyc;
  endtask

  //==========================================================================
  // P-Channel : power-state change request
  //   set pstate + preq -> wait paccept/pdeny -> drop preq -> wait handshake low
  //==========================================================================
  protected task do_pch_req(crlp_seq_item item);
    int unsigned cyc = 0;
    bit done = 0;

    if (!clk_enabled) clk_enabled = 1;    // P-Channel handshake needs clock

    @(vif.drv_cb);
    vif.drv_cb.pstate <= item.pstate;
    vif.drv_cb.preq   <= 1'b1;

    while (!done && cyc < cfg.pch_timeout_cycles) begin
      @(vif.drv_cb);
      cyc++;
      if (vif.drv_cb.paccept === 1'b1) begin item.rsp = RSP_ACCEPT; done = 1; end
      else if (vif.drv_cb.pdeny === 1'b1) begin item.rsp = RSP_DENY;   done = 1; end
    end

    // Complete the handshake : deassert preq, wait for accept/deny to drop.
    vif.drv_cb.preq <= 1'b0;
    if (done) begin
      do @(vif.drv_cb);
      while (vif.drv_cb.paccept !== 1'b0 || vif.drv_cb.pdeny !== 1'b0);
      `uvm_info(get_type_name(),
        $sformatf("P-Channel pstate=0x%0h %s", item.pstate,
                  (item.rsp==RSP_ACCEPT)?"ACCEPTED":"DENIED"), UVM_MEDIUM)
    end
    else begin
      item.rsp = RSP_TIMEOUT;
      `uvm_error(get_type_name(),
        $sformatf("P-Channel request TIMEOUT (pstate=0x%0h)", item.pstate))
    end
    item.latency_cy = cyc;
  endtask

endclass

`endif // CRLP_DRIVER_SVH
