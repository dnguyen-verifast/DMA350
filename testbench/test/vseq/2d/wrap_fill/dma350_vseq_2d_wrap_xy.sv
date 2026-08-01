//==============================================================================
// dma350_vseq_2d_wrap_xy.sv
//   GROUP B - TRM 5.3.2.2, wrap ca hai chieu (tiling)
//   Nguon 4x2 duoc lat gach ra vung dich 8x4 (XTYPE=wrap, YTYPE=wrap).
//   Ky vong: khoi nguon lap 2 lan theo X va 2 lan theo Y.
//==============================================================================
`ifndef DMA350_VSEQ_2D_WRAP_XY_SV
`define DMA350_VSEQ_2D_WRAP_XY_SV

class dma350_vseq_2d_wrap_xy extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_wrap_xy)

  function new(string name = "dma350_vseq_2d_wrap_xy");
    super.new(name);
    src_xsize   = 4;
    des_xsize   = 8;
    src_ysize = 2;
    des_ysize = 4;
    xtype = XT_WRAP;
    ytype = YT_WRAP;
    src_ystride = 'h20;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_wrap_xy

`endif // DMA350_VSEQ_2D_WRAP_XY_SV
