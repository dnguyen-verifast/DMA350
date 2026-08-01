//==============================================================================
// dma350_vseq_2d_xform_transpose.sv
//   GROUP D - TRM 5.3.1 (transpose = lat qua duong cheo)
//   DESXADDRINC = so element mot dong, DESYADDRSTRIDE = kich thuoc mot element.
//   Ky vong: dst[y][x] == src[x][y] tren toan khoi.
//==============================================================================
`ifndef DMA350_VSEQ_2D_XFORM_TRANSPOSE_SV
`define DMA350_VSEQ_2D_XFORM_TRANSPOSE_SV

class dma350_vseq_2d_xform_transpose extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_xform_transpose)

  function new(string name = "dma350_vseq_2d_xform_transpose");
    super.new(name);
    src_xsize = 8;
    des_xsize = 8;
    src_ysize = 8;
    des_ysize = 8;
    src_ystride  = 'h20;
    des_xaddrinc = 8;
    des_ystride  = 'h4;
    chk_src_drained = 1;
  endfunction

endclass : dma350_vseq_2d_xform_transpose

`endif // DMA350_VSEQ_2D_XFORM_TRANSPOSE_SV
