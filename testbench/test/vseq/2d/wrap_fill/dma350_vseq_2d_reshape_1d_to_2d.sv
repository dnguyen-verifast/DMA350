//==============================================================================
// dma350_vseq_2d_reshape_1d_to_2d.sv
//   GROUP B - TRM 5.3.2.2 (XTYPE=continue cho phep chuyen 1D -> 2D)
//   Nguon la MOT dong dai (SRCYSIZE=1, 32 element), dich la khoi 8x4.
//   Ky vong: dong nguon duoc cat thanh 4 dong dich lien tiep.
//==============================================================================
`ifndef DMA350_VSEQ_2D_RESHAPE_1D_TO_2D_SV
`define DMA350_VSEQ_2D_RESHAPE_1D_TO_2D_SV

class dma350_vseq_2d_reshape_1d_to_2d extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_reshape_1d_to_2d)

  function new(string name = "dma350_vseq_2d_reshape_1d_to_2d");
    super.new(name);
    src_xsize = 32;
    src_ysize = 1;
    des_xsize = 8;
    des_ysize = 4;
    xtype = XT_CONT;
    ytype = YT_CONT;
    src_ystride = 'h80;
    des_ystride = 'h20;
    chk_src_drained = 1;
  endfunction

endclass : dma350_vseq_2d_reshape_1d_to_2d

`endif // DMA350_VSEQ_2D_RESHAPE_1D_TO_2D_SV
