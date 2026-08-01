//==============================================================================
// dma350_vseq_2d_reshape_2d_to_1d.sv
//   GROUP B - TRM 5.3.2.2 (XTYPE=continue cho phep chuyen 2D -> 1D)
//   Nguon la khoi 8x4, dich la MOT dong dai (DESYSIZE=1, 32 element).
//   Ky vong: 4 dong nguon duoc noi lai thanh mot dong dich lien tuc.
//==============================================================================
`ifndef DMA350_VSEQ_2D_RESHAPE_2D_TO_1D_SV
`define DMA350_VSEQ_2D_RESHAPE_2D_TO_1D_SV

class dma350_vseq_2d_reshape_2d_to_1d extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_reshape_2d_to_1d)

  function new(string name = "dma350_vseq_2d_reshape_2d_to_1d");
    super.new(name);
    src_xsize = 8;
    src_ysize = 4;
    des_xsize = 32;
    des_ysize = 1;
    xtype = XT_CONT;
    ytype = YT_CONT;
    src_ystride = 'h20;
    des_ystride = 'h80;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_reshape_2d_to_1d

`endif // DMA350_VSEQ_2D_RESHAPE_2D_TO_1D_SV
