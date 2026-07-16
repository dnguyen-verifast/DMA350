//============================================================================
// dma_trig_in_sequencer.sv  -- sequencer for the trigger-IN (requester) agent.
//============================================================================
`ifndef DMA_TRIG_IN_SEQUENCER_SV
`define DMA_TRIG_IN_SEQUENCER_SV

class dma_trig_in_sequencer extends uvm_sequencer #(dma_trig_item);
  `uvm_component_utils(dma_trig_in_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass : dma_trig_in_sequencer

`endif // DMA_TRIG_IN_SEQUENCER_SV
