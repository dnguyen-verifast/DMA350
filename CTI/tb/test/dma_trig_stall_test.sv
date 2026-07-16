//============================================================================
// dma_trig_stall_test.sv
// Channel-stall: trig-out responders ACK after a very long delay so the DMA
// channel stalls before DONE (TRM 5.4.2).
//============================================================================
`ifndef DMA_TRIG_STALL_TEST_SV
`define DMA_TRIG_STALL_TEST_SV

class dma_trig_stall_test extends dma_trig_base_test;
  `uvm_component_utils(dma_trig_stall_test)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    dma_trig_stall_vseq vseq;
    phase.raise_objection(this);
    vseq = dma_trig_stall_vseq::type_id::create("vseq");
    void'(vseq.randomize());
    vseq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : dma_trig_stall_test

`endif // DMA_TRIG_STALL_TEST_SV
