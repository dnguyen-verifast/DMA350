//==============================================================================
// dma350_vseq_2d_xform_rotate_90.sv
//   GROUP D - TRM 5.3.1 Figure 5-7 'Rotation' 90 do (cung chieu kim dong ho)
//   Doi vai tro X/Y o phia dich: DESXADDRINC = mot dong (stride), DESYADDRSTRIDE
//   = mot element -> element ke tiep trong dong nguon roi xuong dong ke tiep o dich.
//   Khoi 8x8 de DESXSIZE/DESYSIZE hoan doi duoc.
//   Ky vong: anh dich = anh nguon xoay 90 do CW.
//==============================================================================
`ifndef DMA350_VSEQ_2D_XFORM_ROTATE_90_SV
`define DMA350_VSEQ_2D_XFORM_ROTATE_90_SV

class dma350_vseq_2d_xform_rotate_90 extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_xform_rotate_90)

  function new(string name = "dma350_vseq_2d_xform_rotate_90");
    super.new(name);
    src_xsize = 8;
    des_xsize = 8;
    src_ysize = 8;
    des_ysize = 8;
    src_ystride  = 'h20;
    des_xaddrinc = 8;
    des_ystride  = -'h4;
    des_addr     = 32'h0006_801C;
    chk_src_drained = 1;
  endfunction

endclass : dma350_vseq_2d_xform_rotate_90

`endif // DMA350_VSEQ_2D_XFORM_ROTATE_90_SV
