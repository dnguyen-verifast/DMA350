//==============================================================================
// dma350_2d_neg_ytype_disabled_ysize_test.sv
//   GROUP X - TRM 5.3.2 'disable: No 2D transfer occurs, the YSIZE and
//   YADDRSTRIDE values are ignored'
//==============================================================================
`ifndef DMA350_2D_NEG_YTYPE_DISABLED_YSIZE_TEST_SV
`define DMA350_2D_NEG_YTYPE_DISABLED_YSIZE_TEST_SV

class dma350_2d_neg_ytype_disabled_ysize_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_neg_ytype_disabled_ysize_test)

  function new(string name = "dma350_2d_neg_ytype_disabled_ysize_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_neg_ytype_disabled_ysize vseq = dma350_vseq_2d_neg_ytype_disabled_ysize::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_neg_ytype_disabled_ysize_test

`endif // DMA350_2D_NEG_YTYPE_DISABLED_YSIZE_TEST_SV
