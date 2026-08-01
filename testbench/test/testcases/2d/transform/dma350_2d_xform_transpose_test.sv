//==============================================================================
// dma350_2d_xform_transpose_test.sv
//   GROUP D - TRM 5.3.1 (transpose = lat qua duong cheo)
//   DESXADDRINC = so element mot dong, DESYADDRSTRIDE = kich thuoc mot element.
//==============================================================================
`ifndef DMA350_2D_XFORM_TRANSPOSE_TEST_SV
`define DMA350_2D_XFORM_TRANSPOSE_TEST_SV

class dma350_2d_xform_transpose_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_xform_transpose_test)

  function new(string name = "dma350_2d_xform_transpose_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_xform_transpose vseq = dma350_vseq_2d_xform_transpose::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_xform_transpose_test

`endif // DMA350_2D_XFORM_TRANSPOSE_TEST_SV
