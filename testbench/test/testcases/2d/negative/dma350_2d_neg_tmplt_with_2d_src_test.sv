//==============================================================================
// dma350_2d_neg_tmplt_with_2d_src_test.sv
//   GROUP X (AM) - TRM 5.9.2.2 'Templated transfers are not allowed with 2D
//   transfer types' : YTYPE != disable va SRCTMPLTSIZE != 0.
//==============================================================================
`ifndef DMA350_2D_NEG_TMPLT_WITH_2D_SRC_TEST_SV
`define DMA350_2D_NEG_TMPLT_WITH_2D_SRC_TEST_SV

class dma350_2d_neg_tmplt_with_2d_src_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_neg_tmplt_with_2d_src_test)

  function new(string name = "dma350_2d_neg_tmplt_with_2d_src_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_neg_tmplt_with_2d_src vseq = dma350_vseq_2d_neg_tmplt_with_2d_src::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_neg_tmplt_with_2d_src_test

`endif // DMA350_2D_NEG_TMPLT_WITH_2D_SRC_TEST_SV
