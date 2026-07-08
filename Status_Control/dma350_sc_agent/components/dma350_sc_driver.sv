//==============================================================================
// dma350_sc_driver.sv
//------------------------------------------------------------------------------
// Drives the DUT inputs of the control interface:
//   G2  stop  : allch_stop_req_{nonsec,sec}    (4-phase, ack is DUT output)
//   G2b pause : allch_pause_req_{nonsec,sec}   (4-phase)
//   G3  CTI   : halt_req (level), restart_req (pulse)
//
// Handshake reference (spec 4.8.2): the req/ack pairs are "simple 4-phase
// handshakes":
//     phase 1: TB asserts req
//     phase 2: DUT asserts ack   (all matching-domain channels stopped/paused)
//     phase 3: TB deasserts req
//     phase 4: DUT deasserts ack
//
// STOP vs PAUSE (verification-critical distinction, 4.8.2):
//   stop  = cancel : DUT still waits for outstanding read/write responses but
//                    stops issuing new requests and stops asserting triggers.
//   pause = freeze : enable bit stays asserted, all transfer/trigger state is
//                    kept; deasserting the request resumes the operation.
//
// CTI (4.8.3): halt_req is a LEVEL input (hold high to stay halted),
// restart_req is a PULSE input, halted is a PULSE output (sampled by monitor).
// The three pause sources (CTI halt, allch_pause, SW allchpause) are OR-ed in
// the DUT, so a CTI halt while a pause is active is a legal overlap.
//
// Build-awareness: the driver refuses to drive a Secure request when the build
// has no Security Extension (cfg.secext_present=0); it reports and downgrades
// SC_SEC/SC_BOTH to the Non-secure path so a mis-targeted stimulus can't drive
// a non-existent wire.
//==============================================================================
`ifndef DMA350_SC_DRIVER__SV
`define DMA350_SC_DRIVER__SV

class dma350_sc_driver extends uvm_driver #(dma350_sc_item);
  `uvm_component_utils(dma350_sc_driver)

  virtual dma350_sc_if.DRV vif;
  dma350_sc_cfg            cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(dma350_sc_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "cfg not set for driver")
    if (!uvm_config_db#(virtual dma350_sc_if.DRV)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "vif (DRV modport) not set for driver")
  endfunction

  task run_phase(uvm_phase phase);
    reset_inputs();
    forever begin
      dma350_sc_item tr;
      // Hold benign levels while waiting for the next item.
      @(vif.drv_cb);
      seq_item_port.get_next_item(tr);
      drive_item(tr);
      seq_item_port.item_done();
    end
  endtask

  // --------------------------------------------------------------------------
  // Reset behaviour: drive all TB-controlled inputs to their deasserted level.
  // --------------------------------------------------------------------------
  task reset_inputs();
    vif.drv_cb.allch_stop_req_nonsec  <= 1'b0;
    vif.drv_cb.allch_stop_req_sec     <= 1'b0;
    vif.drv_cb.allch_pause_req_nonsec <= 1'b0;
    vif.drv_cb.allch_pause_req_sec    <= 1'b0;
    vif.drv_cb.halt_req               <= 1'b0;
    vif.drv_cb.restart_req            <= 1'b0;
  endtask

  // --------------------------------------------------------------------------
  // Dispatch on the requested op.
  // --------------------------------------------------------------------------
  task drive_item(dma350_sc_item tr);
    case (tr.op)
      SC_NOP, SC_GPO_SAMPLE : /* no drive; trailing idle provides the gap */ ;
      SC_STOP               : do_stop(tr);
      SC_PAUSE              : do_pause(tr);
      SC_RESUME             : do_resume(tr);
      SC_HALT               : do_halt(tr);
      SC_RESTART            : do_restart(tr);
      default               : ;
    endcase
    idle(tr.duration);   // inter-item gap (single source of `duration`)
  endtask

  task idle(int unsigned n);
    repeat (n) @(vif.drv_cb);
  endtask

  // --------------------------------------------------------------------------
  // Resolve the effective domain given the build (guards non-existent _sec).
  // --------------------------------------------------------------------------
  function dma350_sc_dom_e eff_domain(dma350_sc_dom_e req);
    if (!cfg.secext_present && (req != SC_NONSEC)) begin
      `uvm_warning(get_type_name(),
        $sformatf("Secure request '%s' requested but SECEXT_PRESENT=0; downgrading to NONSEC",
                  req.name()))
      return SC_NONSEC;
    end
    return req;
  endfunction

  // --------------------------------------------------------------------------
  // Group 2 : STOP  (4-phase, per domain)
  // --------------------------------------------------------------------------
  task do_stop(dma350_sc_item tr);
    dma350_sc_dom_e d = eff_domain(tr.domain);
    `uvm_info(get_type_name(),
      $sformatf("STOP request  domain=%s hold=%0d", d.name(), tr.hold_cycles), UVM_MEDIUM)

    // phase 1: assert req(s)
    if (d inside {SC_NONSEC, SC_BOTH}) vif.drv_cb.allch_stop_req_nonsec <= 1'b1;
    if (d inside {SC_SEC,    SC_BOTH}) vif.drv_cb.allch_stop_req_sec    <= 1'b1;
    @(vif.drv_cb);

    // phase 2: wait ack(s)
    if (d inside {SC_NONSEC, SC_BOTH})
      wait_ack("stop_ack_nonsec", 0 /*nonsec*/, 1'b1);
    if (d inside {SC_SEC, SC_BOTH})
      wait_ack("stop_ack_sec", 1 /*sec*/, 1'b1);

    // caller may keep the request asserted (e.g. to enable a channel and check
    // it is stopped immediately while the request is still high).
    repeat (tr.hold_cycles) @(vif.drv_cb);

    // phase 3: deassert req(s)
    if (d inside {SC_NONSEC, SC_BOTH}) vif.drv_cb.allch_stop_req_nonsec <= 1'b0;
    if (d inside {SC_SEC,    SC_BOTH}) vif.drv_cb.allch_stop_req_sec    <= 1'b0;

    // phase 4: wait ack deassert(s)
    if (d inside {SC_NONSEC, SC_BOTH})
      wait_ack("stop_ack_nonsec", 0, 1'b0);
    if (d inside {SC_SEC, SC_BOTH})
      wait_ack("stop_ack_sec", 1, 1'b0);
  endtask

  // --------------------------------------------------------------------------
  // Group 2b : PAUSE  (4-phase, per domain).  Same handshake as stop; the
  // difference is purely in DUT behaviour (freeze vs cancel), checked by SB.
  // If hold_cycles>0 we keep the pause asserted; SC_RESUME (or duration=0
  // release) resumes.
  // --------------------------------------------------------------------------
  task do_pause(dma350_sc_item tr);
    dma350_sc_dom_e d = eff_domain(tr.domain);
    `uvm_info(get_type_name(),
      $sformatf("PAUSE request domain=%s hold=%0d", d.name(), tr.hold_cycles), UVM_MEDIUM)

    if (d inside {SC_NONSEC, SC_BOTH}) vif.drv_cb.allch_pause_req_nonsec <= 1'b1;
    if (d inside {SC_SEC,    SC_BOTH}) vif.drv_cb.allch_pause_req_sec    <= 1'b1;
    @(vif.drv_cb);

    if (d inside {SC_NONSEC, SC_BOTH})
      wait_ack("pause_ack_nonsec", 0, 1'b1, .pause(1));
    if (d inside {SC_SEC, SC_BOTH})
      wait_ack("pause_ack_sec", 1, 1'b1, .pause(1));

    // Hold paused. If auto-release requested (hold_cycles>0 and not RESUME
    // separately), release here so a single item is self-contained.
    repeat (tr.hold_cycles) @(vif.drv_cb);

    if (tr.hold_cycles != 0) begin
      // self-contained pause/resume
      if (d inside {SC_NONSEC, SC_BOTH}) vif.drv_cb.allch_pause_req_nonsec <= 1'b0;
      if (d inside {SC_SEC,    SC_BOTH}) vif.drv_cb.allch_pause_req_sec    <= 1'b0;
      if (d inside {SC_NONSEC, SC_BOTH})
        wait_ack("pause_ack_nonsec", 0, 1'b0, .pause(1));
      if (d inside {SC_SEC, SC_BOTH})
        wait_ack("pause_ack_sec", 1, 1'b0, .pause(1));
    end
    // else: leave asserted; a later SC_RESUME item releases it.
  endtask

  // --------------------------------------------------------------------------
  // Release a held pause (deassert req, wait ack low). Domain-aware.
  // --------------------------------------------------------------------------
  task do_resume(dma350_sc_item tr);
    dma350_sc_dom_e d = eff_domain(tr.domain);
    `uvm_info(get_type_name(),
      $sformatf("RESUME (release pause) domain=%s", d.name()), UVM_MEDIUM)
    if (d inside {SC_NONSEC, SC_BOTH}) vif.drv_cb.allch_pause_req_nonsec <= 1'b0;
    if (d inside {SC_SEC,    SC_BOTH}) vif.drv_cb.allch_pause_req_sec    <= 1'b0;
    if (d inside {SC_NONSEC, SC_BOTH})
      wait_ack("pause_ack_nonsec", 0, 1'b0, .pause(1));
    if (d inside {SC_SEC, SC_BOTH})
      wait_ack("pause_ack_sec", 1, 1'b0, .pause(1));
  endtask

  // --------------------------------------------------------------------------
  // Group 3 : CTI halt (level). Assert halt_req and keep it high; optionally
  // auto-restart after hold_cycles. The `halted` pulse is observed by monitor.
  // --------------------------------------------------------------------------
  task do_halt(dma350_sc_item tr);
    `uvm_info(get_type_name(),
      $sformatf("CTI HALT (level) hold=%0d auto_restart=%0b",
                tr.hold_cycles, tr.auto_restart), UVM_MEDIUM)
    vif.drv_cb.halt_req <= 1'b1;         // level: keep asserted
    repeat ((tr.hold_cycles == 0) ? 1 : tr.hold_cycles) @(vif.drv_cb);
    if (tr.auto_restart) begin
      vif.drv_cb.halt_req <= 1'b0;       // drop the halt level ...
      @(vif.drv_cb);
      pulse_restart();                   // ... then pulse restart
    end
    // else: leave halt_req high; a later SC_RESTART item resumes.
  endtask

  // --------------------------------------------------------------------------
  // Group 3 : CTI restart (pulse). Also drops any held halt level first.
  // --------------------------------------------------------------------------
  task do_restart(dma350_sc_item tr);
    `uvm_info(get_type_name(), "CTI RESTART (pulse)", UVM_MEDIUM)
    vif.drv_cb.halt_req <= 1'b0;
    @(vif.drv_cb);
    pulse_restart();
  endtask

  task pulse_restart();
    vif.drv_cb.restart_req <= 1'b1;
    repeat (cfg.pulse_len) @(vif.drv_cb);
    vif.drv_cb.restart_req <= 1'b0;
    @(vif.drv_cb);
  endtask

  // --------------------------------------------------------------------------
  // Wait for a stop/pause ack to reach `level`, with timeout + reset abort.
  //   sel : 0 = nonsec, 1 = sec
  //   pause: 0 = stop ack, 1 = pause ack
  // --------------------------------------------------------------------------
  task wait_ack(string tag, bit sel, bit level, bit pause = 0);
    int unsigned cnt = 0;
    forever begin
      bit ack;
      @(vif.drv_cb);
      if (!vif.resetn) begin
        `uvm_warning(get_type_name(), $sformatf("reset during %s handshake", tag))
        return;
      end
      ack = pause ?
              (sel ? vif.drv_cb.allch_pause_ack_sec : vif.drv_cb.allch_pause_ack_nonsec) :
              (sel ? vif.drv_cb.allch_stop_ack_sec  : vif.drv_cb.allch_stop_ack_nonsec);
      if (ack === level) return;
      cnt++;
      if (cfg.handshake_timeout != 0 && cnt > cfg.handshake_timeout)
        `uvm_error(get_type_name(),
          $sformatf("TIMEOUT waiting %s -> %0b after %0d cycles", tag, level, cnt))
    end
  endtask

endclass : dma350_sc_driver

`endif // DMA350_SC_DRIVER__SV
