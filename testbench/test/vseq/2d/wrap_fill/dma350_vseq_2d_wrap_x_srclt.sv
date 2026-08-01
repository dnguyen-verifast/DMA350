//==============================================================================
// dma350_vseq_2d_wrap_x_srclt.sv
//   GROUP B - TRM 5.3.2.2 'SRCXSIZE < DESXSIZE', XTYPE = wrap
//   Dong nguon (4 element) ngan hon dong dich (8 element).
//   Ky vong: het dong nguon thi doc lai tu dau dong -> dong dich duoc lap 2 lan.
//==============================================================================
`ifndef DMA350_VSEQ_2D_WRAP_X_SRCLT_SV
`define DMA350_VSEQ_2D_WRAP_X_SRCLT_SV

class dma350_vseq_2d_wrap_x_srclt extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_wrap_x_srclt)

  function new(string name = "dma350_vseq_2d_wrap_x_srclt");
    super.new(name);
    src_xsize   = 4;
    des_xsize   = 8;
    xtype       = XT_WRAP;
    src_ystride = 'h20;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_wrap_x_srclt

`endif // DMA350_VSEQ_2D_WRAP_X_SRCLT_SV
