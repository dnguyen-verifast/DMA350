//==============================================================================
// dma350_2d_xform_rotate_270_test.sv
//   GROUP D - TRM 5.3.1 Figure 5-7 'Rotation' 270 do (90 do nguoc kim dong ho)
//   Nghich dau so voi rotate_90: DESXADDRINC am theo cot, DESYADDRSTRIDE duong.
//==============================================================================
`ifndef DMA350_2D_XFORM_ROTATE_270_TEST_SV
`define DMA350_2D_XFORM_ROTATE_270_TEST_SV

class dma350_2d_xform_rotate_270_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_xform_rotate_270_test)

  function new(string name = "dma350_2d_xform_rotate_270_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_xform_rotate_270 vseq = dma350_vseq_2d_xform_rotate_270::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_xform_rotate_270_test

`endif // DMA350_2D_XFORM_ROTATE_270_TEST_SV
