//============================================================================
// dma_trig_out_sequencer.sv  -- sequencer for the trigger-OUT (responder) agent.
//============================================================================
`ifndef DMA_TRIG_OUT_SEQUENCER_SV
`define DMA_TRIG_OUT_SEQUENCER_SV

class dma_trig_out_sequencer extends uvm_sequencer #(dma_trig_item);
  `uvm_component_utils(dma_trig_out_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass : dma_trig_out_sequencer

`endif // DMA_TRIG_OUT_SEQUENCER_SV
