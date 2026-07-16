//============================================================================
// dma_trig_in_single_seq.sv  -- one SINGLE request (TRM Table 5-4).
//============================================================================
`ifndef DMA_TRIG_IN_SINGLE_SEQ_SV
`define DMA_TRIG_IN_SINGLE_SEQ_SV

class dma_trig_in_single_seq extends dma_trig_in_base_seq;
  `uvm_object_utils(dma_trig_in_single_seq)
  rand int unsigned pre_delay = 0;
  constraint c_d { soft pre_delay inside {[0:8]}; }
  function new(string name = "dma_trig_in_single_seq");
    super.new(name);
  endfunction
  task body();
    `uvm_do_with(req, { req.reqtype == DMA_TRIG_SINGLE;
                        req.pre_delay == local::pre_delay; })
  endtask
endclass : dma_trig_in_single_seq

`endif // DMA_TRIG_IN_SINGLE_SEQ_SV
