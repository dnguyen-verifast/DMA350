//==============================================================================
// dma350_sc_stop_seq.sv  (Group 2 - Stop control, 4.8.2)
//------------------------------------------------------------------------------
// Drives all-channel STOP handshakes. Includes the spec corner case: keep the
// stop request asserted (hold_cycles) so that a channel enabled by SW while the
// request is high is stopped immediately.
//==============================================================================
`ifndef DMA350_SC_STOP_SEQ__SV
`define DMA350_SC_STOP_SEQ__SV

class dma350_sc_stop_seq extends dma350_sc_base_seq;
  `uvm_object_utils(dma350_sc_stop_seq)

  rand dma350_sc_dom_e domain = SC_NONSEC;
  rand int unsigned    hold   = 0;

  function new(string name = "dma350_sc_stop_seq");
    super.new(name);
  endfunction

  task body();
    dma350_sc_dom_e d = domain;
    if (!cfg.secext_present && d != SC_NONSEC) d = SC_NONSEC; // build guard
    `uvm_info(get_type_name(), $sformatf("STOP seq domain=%s hold=%0d", d.name(), hold), UVM_LOW)
    send(SC_STOP, d, hold);
  endtask
endclass : dma350_sc_stop_seq

`endif // DMA350_SC_STOP_SEQ__SV
