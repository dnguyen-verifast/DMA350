//==============================================================================
// crlp_monitor.svh
//   Passively observes reset, Q-Channel and P-Channel handshakes and broadcasts
//   reconstructed transactions on ap.  Also performs protocol assertions.
//==============================================================================
`ifndef CRLP_MONITOR_SVH
`define CRLP_MONITOR_SVH

class crlp_monitor extends uvm_monitor;
  `uvm_component_utils(crlp_monitor)

  crlp_config     cfg;
  virtual crlp_if vif;

  uvm_analysis_port #(crlp_seq_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(crlp_config)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "crlp_config not set in config_db")
    vif = cfg.vif;
  endfunction

  //--------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    fork
      mon_reset();
      mon_qchannel();
      mon_pchannel();
    join_none
  endtask

  //--------------------------------------------------------------------------
  // Reset observation
  //--------------------------------------------------------------------------
  protected task mon_reset();
    forever begin
      @(negedge vif.resetn);
      `uvm_info(get_type_name(), "resetn asserted (LOW)", UVM_MEDIUM)
      @(posedge vif.resetn);
      // resetn must rise synchronously (aligned to a rising clk edge).
      begin
        crlp_seq_item t = crlp_seq_item::type_id::create("rst_obs");
        t.op = OP_RESET;
        ap.write(t);
      end
      `uvm_info(get_type_name(), "resetn deasserted (HIGH)", UVM_MEDIUM)
    end
  endtask

  //--------------------------------------------------------------------------
  // Q-Channel observation : capture request->response transactions
  //--------------------------------------------------------------------------
  protected task mon_qchannel();
    int unsigned cyc;
    forever begin
      // Wait for a quiescence request : qreqn goes LOW.
      do @(vif.mon_cb); while (vif.mon_cb.clk_qreqn !== 1'b0);
      cyc = 0;
      forever begin
        @(vif.mon_cb);
        cyc++;
        if (vif.mon_cb.clk_qacceptn === 1'b0 && vif.mon_cb.clk_qdeny === 1'b0) begin
          emit_q(RSP_ACCEPT, cyc);  break;
        end
        else if (vif.mon_cb.clk_qdeny === 1'b1) begin
          emit_q(RSP_DENY, cyc);    break;
        end
        else if (vif.mon_cb.clk_qreqn === 1'b1) begin
          break;                    // request withdrawn before response
        end
      end
    end
  endtask

  protected function void emit_q(crlp_rsp_e r, int unsigned cyc);
    crlp_seq_item t = crlp_seq_item::type_id::create("qch_obs");
    t.op         = OP_QCH_QUIESCE;
    t.rsp        = r;
    t.latency_cy = cyc;
    ap.write(t);
    `uvm_info(get_type_name(),
      $sformatf("Observed Q-Channel %s (lat=%0d)", r.name(), cyc), UVM_HIGH)
  endfunction

  //--------------------------------------------------------------------------
  // P-Channel observation
  //--------------------------------------------------------------------------
  protected task mon_pchannel();
    int unsigned cyc;
    bit [3:0]    req_state;
    forever begin
      do @(vif.mon_cb); while (vif.mon_cb.preq !== 1'b1);
      req_state = vif.mon_cb.pstate;
      cyc = 0;
      forever begin
        @(vif.mon_cb);
        cyc++;
        if (vif.mon_cb.paccept === 1'b1) begin emit_p(req_state, RSP_ACCEPT, cyc); break; end
        if (vif.mon_cb.pdeny   === 1'b1) begin emit_p(req_state, RSP_DENY,   cyc); break; end
      end
    end
  endtask

  protected function void emit_p(bit [3:0] ps, crlp_rsp_e r, int unsigned cyc);
    crlp_seq_item t = crlp_seq_item::type_id::create("pch_obs");
    t.op         = OP_PCH_REQ;
    t.pstate     = ps;
    t.rsp        = r;
    t.latency_cy = cyc;
    ap.write(t);
    `uvm_info(get_type_name(),
      $sformatf("Observed P-Channel pstate=0x%0h %s (lat=%0d)",
                ps, r.name(), cyc), UVM_HIGH)
  endfunction

endclass

`endif // CRLP_MONITOR_SVH
