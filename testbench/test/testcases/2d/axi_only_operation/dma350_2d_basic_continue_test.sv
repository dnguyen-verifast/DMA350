//==============================================================================
// dma350_2d_basic_continue_test.sv
//   GROUP A - TRM 5.3.1 'Transfer type 2D'
//   Baseline: khoi 2D 8 element x 4 dong, XTYPE=continue YTYPE=continue.
//==============================================================================
`ifndef DMA350_2D_BASIC_CONTINUE_TEST_SV
`define DMA350_2D_BASIC_CONTINUE_TEST_SV

class dma350_2d_basic_continue_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_basic_continue_test)

  function new(string name = "dma350_2d_basic_continue_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_basic_continue vseq = dma350_vseq_2d_basic_continue::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_basic_continue_test

`endif // DMA350_2D_BASIC_CONTINUE_TEST_SV
