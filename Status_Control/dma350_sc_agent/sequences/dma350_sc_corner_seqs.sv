//==============================================================================
// dma350_sc_corner_seqs.sv
//------------------------------------------------------------------------------
// Corner-case sequences the TRM explicitly motivates. These only drive the
// control-interface side; pairing them with data-path / register stimulus (via
// other agents in a virtual sequence) is what makes them meaningful. Each class
// documents the intended DUT check for the scoreboard.
//==============================================================================
`ifndef DMA350_SC_CORNER_SEQS__SV
`define DMA350_SC_CORNER_SEQS__SV

//------------------------------------------------------------------------------
// C1. Multi-source pause OR (4.8.3): assert allch_pause AND CTI halt overlapping.
//     Expect: channels stay paused/halted until BOTH sources are released, and
//     no state is lost.
//------------------------------------------------------------------------------
class dma350_sc_pause_or_halt_seq extends dma350_sc_base_seq;
  `uvm_object_utils(dma350_sc_pause_or_halt_seq)
  function new(string name = "dma350_sc_pause_or_halt_seq"); super.new(name); endfunction
  task body();
    `uvm_info(get_type_name(), "pause+halt OR overlap", UVM_LOW)
    send(SC_PAUSE, SC_NONSEC, 0);          // source A: allch_pause (held)
    send(SC_HALT,  SC_NONSEC, 10);         // source B: CTI halt (held, level)
    send(SC_RESTART, SC_NONSEC, 0);        // release CTI (source B)
    send(SC_NOP,   SC_NONSEC, 0, 8);       // still paused via source A
    send(SC_RESUME, SC_NONSEC, 0);         // release allch_pause (source A)
  endtask
endclass

//------------------------------------------------------------------------------
// C2. Stop while transfers in flight (4.8.2): assert stop and hold it. Pair with
//     a data-path sequence that has outstanding read/write. Scoreboard checks:
//     DUT waits for outstanding responses but issues no new req and no triggers.
//------------------------------------------------------------------------------
class dma350_sc_stop_inflight_seq extends dma350_sc_base_seq;
  `uvm_object_utils(dma350_sc_stop_inflight_seq)
  rand dma350_sc_dom_e domain = SC_NONSEC;
  function new(string name = "dma350_sc_stop_inflight_seq"); super.new(name); endfunction
  task body();
    dma350_sc_dom_e d = (!cfg.secext_present) ? SC_NONSEC : domain;
    `uvm_info(get_type_name(), $sformatf("stop-in-flight domain=%s", d.name()), UVM_LOW)
    send(SC_STOP, d, 32);   // hold the stop request across the in-flight window
  endtask
endclass

//------------------------------------------------------------------------------
// C3. Enable-during-request (4.8.2): keep stop (or pause) req asserted long
//     enough that a channel enabled by SW mid-window is stopped/paused
//     immediately. Pair with a register agent that sets ENABLECMD while held.
//------------------------------------------------------------------------------
class dma350_sc_enable_during_stop_seq extends dma350_sc_base_seq;
  `uvm_object_utils(dma350_sc_enable_during_stop_seq)
  rand bit use_pause = 1'b0;   // 0 => stop, 1 => pause
  function new(string name = "dma350_sc_enable_during_stop_seq"); super.new(name); endfunction
  task body();
    `uvm_info(get_type_name(),
      $sformatf("hold %s across a channel-enable window", use_pause?"PAUSE":"STOP"), UVM_LOW)
    // Long hold so the companion register sequence can enable a channel while
    // the request is still asserted.
    send(use_pause ? SC_PAUSE : SC_STOP, SC_NONSEC, 40);
  endtask
endclass

//------------------------------------------------------------------------------
// C4. Secure-domain isolation (SECEXT_PRESENT=1): stop only the Secure domain
//     and confirm Non-secure channels keep running (and vice-versa). Skips
//     itself on non-TZ builds.
//------------------------------------------------------------------------------
class dma350_sc_secure_isolation_seq extends dma350_sc_base_seq;
  `uvm_object_utils(dma350_sc_secure_isolation_seq)
  function new(string name = "dma350_sc_secure_isolation_seq"); super.new(name); endfunction
  task body();
    if (!cfg.secext_present) begin
      `uvm_info(get_type_name(), "SECEXT_PRESENT=0; skipping secure-isolation seq", UVM_LOW)
      return;
    end
    `uvm_info(get_type_name(), "stop SEC only, then PAUSE NONSEC only", UVM_LOW)
    send(SC_STOP,  SC_SEC,    8);   // only Secure channels stop
    send(SC_PAUSE, SC_NONSEC, 8);   // only Non-secure channels pause
  endtask
endclass

//------------------------------------------------------------------------------
// C5. Interleaved stop on BOTH domains in the same window (handshake ordering).
//------------------------------------------------------------------------------
class dma350_sc_both_domain_stop_seq extends dma350_sc_base_seq;
  `uvm_object_utils(dma350_sc_both_domain_stop_seq)
  function new(string name = "dma350_sc_both_domain_stop_seq"); super.new(name); endfunction
  task body();
    dma350_sc_dom_e d = cfg.secext_present ? SC_BOTH : SC_NONSEC;
    `uvm_info(get_type_name(), $sformatf("stop domain=%s", d.name()), UVM_LOW)
    send(SC_STOP, d, 12);
  endtask
endclass

//------------------------------------------------------------------------------
// C6. Random mix of control actions – smoke/regression driver.
//------------------------------------------------------------------------------
class dma350_sc_random_seq extends dma350_sc_base_seq;
  `uvm_object_utils(dma350_sc_random_seq)
  rand int unsigned n = 20;
  function new(string name = "dma350_sc_random_seq"); super.new(name); endfunction
  task body();
    repeat (n) begin
      dma350_sc_item it = dma350_sc_item::type_id::create("it");
      start_item(it);
      if (!it.randomize() with {
            // never target Secure on a non-TZ build
            (local::cfg.secext_present == 0) -> (domain == SC_NONSEC);
            op dist { SC_STOP:=3, SC_PAUSE:=3, SC_HALT:=2, SC_RESTART:=1,
                      SC_NOP:=1, SC_GPO_SAMPLE:=1 };
            hold_cycles inside {[0:24]};
            duration    inside {[1:8]};
          })
        `uvm_error(get_type_name(), "randomize failed")
      finish_item(it);
    end
  endtask
endclass

`endif // DMA350_SC_CORNER_SEQS__SV
