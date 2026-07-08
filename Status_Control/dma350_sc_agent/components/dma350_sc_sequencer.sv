//==============================================================================
// dma350_sc_sequencer.sv
//------------------------------------------------------------------------------
// Plain UVM sequencer for status/control items.
//==============================================================================
`ifndef DMA350_SC_SEQUENCER__SV
`define DMA350_SC_SEQUENCER__SV

class dma350_sc_sequencer extends uvm_sequencer #(dma350_sc_item);
  `uvm_component_utils(dma350_sc_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass : dma350_sc_sequencer

`endif // DMA350_SC_SEQUENCER__SV
