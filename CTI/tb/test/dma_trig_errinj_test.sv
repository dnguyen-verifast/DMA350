//============================================================================
// dma_trig_errinj_test.sv
// Error-injection: a trig-in port mutates req_type while req is held (illegal,
// TRM 5.4.1). The interface stability assertion is EXPECTED to fire -- that is
// the pass criterion (the checker caught the violation).
//============================================================================
`ifndef DMA_TRIG_ERRINJ_TEST_SV
`define DMA_TRIG_ERRINJ_TEST_SV

class dma_trig_errinj_test extends dma_trig_base_test;
  `uvm_component_utils(dma_trig_errinj_test)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    dma_trig_errinj_vseq vseq;
    phase.raise_objection(this);
    vseq = dma_trig_errinj_vseq::type_id::create("vseq");
    void'(vseq.randomize());
    vseq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : dma_trig_errinj_test

`endif // DMA_TRIG_ERRINJ_TEST_SV
