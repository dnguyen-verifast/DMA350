//==============================================================================
// dma350_vseq_2d_xform_overlap_stride.sv
//   GROUP D - TRM 5.3.1 'Special corner cases' (abs(YADDRSTRIDE) < abs(XSIZE*XADDRINC))
//   Stride nho hon do dai mot dong -> cac dong CHONG LEN nhau.
//   TRM coi day la co y (vd FFT/DCT): du lieu duoc doc lai / ghi de.
//   Ky vong: doc lai dung vung chong lan, khong treo, khong bao loi.
//==============================================================================
`ifndef DMA350_VSEQ_2D_XFORM_OVERLAP_STRIDE_SV
`define DMA350_VSEQ_2D_XFORM_OVERLAP_STRIDE_SV

class dma350_vseq_2d_xform_overlap_stride extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_xform_overlap_stride)

  function new(string name = "dma350_vseq_2d_xform_overlap_stride");
    super.new(name);
    src_ystride = 'h10;
    des_ystride = 'h10;
  endfunction

endclass : dma350_vseq_2d_xform_overlap_stride

`endif // DMA350_VSEQ_2D_XFORM_OVERLAP_STRIDE_SV
