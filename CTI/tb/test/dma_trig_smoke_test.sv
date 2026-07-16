//============================================================================
// dma_trig_smoke_test.sv
// Smoke: a few SINGLE requests per trig-in port; trig-out responders ACK.
//============================================================================
`ifndef DMA_TRIG_SMOKE_TEST_SV
`define DMA_TRIG_SMOKE_TEST_SV

class dma_trig_smoke_test extends dma_trig_base_test;
  `uvm_component_utils(dma_trig_smoke_test)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    dma_trig_smoke_vseq vseq;
    phase.raise_objection(this);
    vseq = dma_trig_smoke_vseq::type_id::create("vseq");
    void'(vseq.randomize());
    vseq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : dma_trig_smoke_test

`endif // DMA_TRIG_SMOKE_TEST_SV
