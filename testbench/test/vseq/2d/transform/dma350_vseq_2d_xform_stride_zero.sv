//==============================================================================
// dma350_vseq_2d_xform_stride_zero.sv
//   GROUP D - TRM 5.3.1 (YADDRSTRIDE = 0 o phia dich)
//   Stride dich = 0 -> moi dong nguon deu ghi de len CUNG mot dong dich.
//   Ky vong: dong dich cuoi cung chua noi dung cua dong nguon cuoi.
//==============================================================================
`ifndef DMA350_VSEQ_2D_XFORM_STRIDE_ZERO_SV
`define DMA350_VSEQ_2D_XFORM_STRIDE_ZERO_SV

class dma350_vseq_2d_xform_stride_zero extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_xform_stride_zero)

  function new(string name = "dma350_vseq_2d_xform_stride_zero");
    super.new(name);
    des_ystride = 0;
    chk_src_drained = 1;
  endfunction

endclass : dma350_vseq_2d_xform_stride_zero

`endif // DMA350_VSEQ_2D_XFORM_STRIDE_ZERO_SV
