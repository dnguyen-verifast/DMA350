//==============================================================================
// dma350_2d_neg_tmplt_with_2d_des_test.sv
//   GROUP X (AM) - TRM 5.9.2.2, template PHIA DICH tren lenh 2D
//   YTYPE != disable va DESTMPLTSIZE != 0 -> to hop bi cam.
//==============================================================================
`ifndef DMA350_2D_NEG_TMPLT_WITH_2D_DES_TEST_SV
`define DMA350_2D_NEG_TMPLT_WITH_2D_DES_TEST_SV

class dma350_2d_neg_tmplt_with_2d_des_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_neg_tmplt_with_2d_des_test)

  function new(string name = "dma350_2d_neg_tmplt_with_2d_des_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_neg_tmplt_with_2d_des vseq = dma350_vseq_2d_neg_tmplt_with_2d_des::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_neg_tmplt_with_2d_des_test

`endif // DMA350_2D_NEG_TMPLT_WITH_2D_DES_TEST_SV
