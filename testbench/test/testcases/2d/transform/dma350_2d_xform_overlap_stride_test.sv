//==============================================================================
// dma350_2d_xform_overlap_stride_test.sv
//   GROUP D - TRM 5.3.1 'Special corner cases' (abs(YADDRSTRIDE) < abs(XSIZE*XADDRINC))
//   Stride nho hon do dai mot dong -> cac dong CHONG LEN nhau.
//==============================================================================
`ifndef DMA350_2D_XFORM_OVERLAP_STRIDE_TEST_SV
`define DMA350_2D_XFORM_OVERLAP_STRIDE_TEST_SV

class dma350_2d_xform_overlap_stride_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_xform_overlap_stride_test)

  function new(string name = "dma350_2d_xform_overlap_stride_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_xform_overlap_stride vseq = dma350_vseq_2d_xform_overlap_stride::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_xform_overlap_stride_test

`endif // DMA350_2D_XFORM_OVERLAP_STRIDE_TEST_SV
