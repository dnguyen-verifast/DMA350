//==============================================================================
// dma350_vseq_2d_wrap_y_srclt.sv
//   GROUP B - TRM 5.3.2.2 'SRCYSIZE < DESYSIZE', YTYPE = wrap
//   Vung nguon 2 dong, vung dich 4 dong.
//   Ky vong: con tro dong quay ve dong dau -> 2 dong nguon duoc lap lai lan 2.
//==============================================================================
`ifndef DMA350_VSEQ_2D_WRAP_Y_SRCLT_SV
`define DMA350_VSEQ_2D_WRAP_Y_SRCLT_SV

class dma350_vseq_2d_wrap_y_srclt extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_wrap_y_srclt)

  function new(string name = "dma350_vseq_2d_wrap_y_srclt");
    super.new(name);
    src_ysize = 2;
    des_ysize = 4;
    ytype     = YT_WRAP;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_wrap_y_srclt

`endif // DMA350_VSEQ_2D_WRAP_Y_SRCLT_SV
