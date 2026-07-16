//============================================================================
// dma_trig_distribute_test.sv
// Full reqtype mix on every trig-in port, command-mode ack semantics.
//============================================================================
`ifndef DMA_TRIG_DISTRIBUTE_TEST_SV
`define DMA_TRIG_DISTRIBUTE_TEST_SV

class dma_trig_distribute_test extends dma_trig_base_test;
  `uvm_component_utils(dma_trig_distribute_test)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    dma_trig_distribute_vseq vseq;
    phase.raise_objection(this);
    vseq = dma_trig_distribute_vseq::type_id::create("vseq");
    if (!vseq.randomize() with { rounds == 4; })
      `uvm_error(get_type_name(), "randomize failed")
    vseq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : dma_trig_distribute_test

`endif // DMA_TRIG_DISTRIBUTE_TEST_SV
