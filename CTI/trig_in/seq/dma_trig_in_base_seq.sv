//============================================================================
// dma_trig_in_base_seq.sv  -- base for trigger-IN (requester) sequences.
//============================================================================
`ifndef DMA_TRIG_IN_BASE_SEQ_SV
`define DMA_TRIG_IN_BASE_SEQ_SV

class dma_trig_in_base_seq extends uvm_sequence #(dma_trig_item);
  `uvm_object_utils(dma_trig_in_base_seq)
  function new(string name = "dma_trig_in_base_seq");
    super.new(name);
  endfunction
endclass : dma_trig_in_base_seq

`endif // DMA_TRIG_IN_BASE_SEQ_SV
