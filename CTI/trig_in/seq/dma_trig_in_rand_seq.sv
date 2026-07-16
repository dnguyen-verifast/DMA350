//============================================================================
// dma_trig_in_rand_seq.sv  -- random reqtypes with random gaps (stress).
//============================================================================
`ifndef DMA_TRIG_IN_RAND_SEQ_SV
`define DMA_TRIG_IN_RAND_SEQ_SV

class dma_trig_in_rand_seq extends dma_trig_in_base_seq;
  `uvm_object_utils(dma_trig_in_rand_seq)
  rand int unsigned n;
  constraint c_n { n inside {[10:50]}; }
  function new(string name = "dma_trig_in_rand_seq");
    super.new(name);
  endfunction
  task body();
    repeat (n) `uvm_do(req)
  endtask
endclass : dma_trig_in_rand_seq

`endif // DMA_TRIG_IN_RAND_SEQ_SV
