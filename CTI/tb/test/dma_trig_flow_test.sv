//============================================================================
// dma_trig_flow_test.sv
// Flow-control mode: the scoreboard allows DENY only on SINGLE-family requests.
// Run with +FLOW so the DMA stub actually exercises DENY / LAST_OKAY.
//============================================================================
`ifndef DMA_TRIG_FLOW_TEST_SV
`define DMA_TRIG_FLOW_TEST_SV

class dma_trig_flow_test extends dma_trig_base_test;
  `uvm_component_utils(dma_trig_flow_test)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void configure();
    cfg = dma_trig_cfg::type_id::create("cfg");
    cfg.mode = DMA_TRIG_MODE_FLOW;
  endfunction

  task run_phase(uvm_phase phase);
    dma_trig_distribute_vseq vseq;
    phase.raise_objection(this);
    vseq = dma_trig_distribute_vseq::type_id::create("vseq");
    if (!vseq.randomize() with { rounds == 6; })
      `uvm_error(get_type_name(), "randomize failed")
    vseq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : dma_trig_flow_test

`endif // DMA_TRIG_FLOW_TEST_SV
