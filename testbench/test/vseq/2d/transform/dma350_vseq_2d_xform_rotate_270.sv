//==============================================================================
// dma350_vseq_2d_xform_rotate_270.sv
//   GROUP D - TRM 5.3.1 Figure 5-7 'Rotation' 270 do (90 do nguoc kim dong ho)
//   Nghich dau so voi rotate_90: DESXADDRINC am theo cot, DESYADDRSTRIDE duong.
//   Ky vong: anh dich = anh nguon xoay 270 do; anh xa goc duoc kiem tra.
//==============================================================================
`ifndef DMA350_VSEQ_2D_XFORM_ROTATE_270_SV
`define DMA350_VSEQ_2D_XFORM_ROTATE_270_SV

class dma350_vseq_2d_xform_rotate_270 extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_xform_rotate_270)

  function new(string name = "dma350_vseq_2d_xform_rotate_270");
    super.new(name);
    src_xsize = 8;
    des_xsize = 8;
    src_ysize = 8;
    des_ysize = 8;
    src_ystride  = 'h20;
    des_xaddrinc = -8;
    des_ystride  = 'h4;
    des_addr     = 32'h0006_80E0;
    chk_src_drained = 1;
  endfunction

endclass : dma350_vseq_2d_xform_rotate_270

`endif // DMA350_VSEQ_2D_XFORM_ROTATE_270_SV
