//==============================================================================
// dma350_2d_xform_stride_zero_test.sv
//   GROUP D - TRM 5.3.1 (YADDRSTRIDE = 0 o phia dich)
//   Stride dich = 0 -> moi dong nguon deu ghi de len CUNG mot dong dich.
//==============================================================================
`ifndef DMA350_2D_XFORM_STRIDE_ZERO_TEST_SV
`define DMA350_2D_XFORM_STRIDE_ZERO_TEST_SV

class dma350_2d_xform_stride_zero_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_xform_stride_zero_test)

  function new(string name = "dma350_2d_xform_stride_zero_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_xform_stride_zero vseq = dma350_vseq_2d_xform_stride_zero::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_xform_stride_zero_test

`endif // DMA350_2D_XFORM_STRIDE_ZERO_TEST_SV
