//==============================================================================
// dma350_sc_pause_seq.sv  (Group 2b - Pause control, 4.8.2)
//------------------------------------------------------------------------------
// Drives an all-channel PAUSE, holds it (freeze), then RESUMEs. Use hold>0 for
// a self-contained pause/resume; use split=1 to emit PAUSE and RESUME as two
// separate items (e.g. to interleave a register read while paused).
//==============================================================================
`ifndef DMA350_SC_PAUSE_SEQ__SV
`define DMA350_SC_PAUSE_SEQ__SV

class dma350_sc_pause_seq extends dma350_sc_base_seq;
  `uvm_object_utils(dma350_sc_pause_seq)

  rand dma350_sc_dom_e domain    = SC_NONSEC;
  rand int unsigned    hold      = 16;
  rand bit             split     = 1'b0;   // emit PAUSE then RESUME separately

  function new(string name = "dma350_sc_pause_seq");
    super.new(name);
  endfunction

  task body();
    dma350_sc_dom_e d = domain;
    if (!cfg.secext_present && d != SC_NONSEC) d = SC_NONSEC;
    `uvm_info(get_type_name(),
      $sformatf("PAUSE seq domain=%s hold=%0d split=%0b", d.name(), hold, split), UVM_LOW)
    if (split) begin
      send(SC_PAUSE, d, 0);       // assert & leave held
      send(SC_NOP,   d, 0, hold); // stay paused for `hold` cycles
      send(SC_RESUME,d, 0);       // release
    end
    else begin
      send(SC_PAUSE, d, hold);    // self-contained pause/resume
    end
  endtask
endclass : dma350_sc_pause_seq

`endif // DMA350_SC_PAUSE_SEQ__SV
