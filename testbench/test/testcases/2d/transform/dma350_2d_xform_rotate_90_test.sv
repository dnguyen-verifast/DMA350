//==============================================================================
// dma350_2d_xform_rotate_90_test.sv
//   GROUP D - TRM 5.3.1 Figure 5-7 'Rotation' 90 do (cung chieu kim dong ho)
//   Doi vai tro X/Y o phia dich: DESXADDRINC = mot dong (stride), DESYADDRSTRIDE
//==============================================================================
`ifndef DMA350_2D_XFORM_ROTATE_90_TEST_SV
`define DMA350_2D_XFORM_ROTATE_90_TEST_SV

class dma350_2d_xform_rotate_90_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_xform_rotate_90_test)

  function new(string name = "dma350_2d_xform_rotate_90_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_xform_rotate_90 vseq = dma350_vseq_2d_xform_rotate_90::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_xform_rotate_90_test

`endif // DMA350_2D_XFORM_ROTATE_90_TEST_SV
