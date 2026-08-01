//==============================================================================
// dma350_vseq_2d_fill_x_ycont.sv
//   GROUP B - TRM 5.3.2.2, XTYPE = fill ket hop YTYPE = continue
//   Moi dong dich (9 element) rong hon dong nguon (5) -> vien phai do FILLVAL,
//   so dong hai ben bang nhau nen YTYPE khong tac dong.
//   Ky vong: tao vien fill ben phai o TUNG dong.
//==============================================================================
`ifndef DMA350_VSEQ_2D_FILL_X_YCONT_SV
`define DMA350_VSEQ_2D_FILL_X_YCONT_SV

class dma350_vseq_2d_fill_x_ycont extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_fill_x_ycont)

  function new(string name = "dma350_vseq_2d_fill_x_ycont");
    super.new(name);
    src_xsize = 5;
    des_xsize = 9;
    xtype = XT_FILL;
    ytype = YT_CONT;
    src_ystride = 'h28;
    des_ystride = 'h48;
    fillval = 32'h0F0F_0F0F;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_fill_x_ycont

`endif // DMA350_VSEQ_2D_FILL_X_YCONT_SV
