//==============================================================================
// dma350_vseq_2d_tmplt_both_1d.sv
//   GROUP E - TRM 5.3.3, template CA HAI phia
//   Nguon va dich deu co template rieng (kich thuoc chu ky khac nhau).
//   TRM: hai phia cau hinh doc lap duoc.
//   Ky vong: dia chi hai ben doc lap theo mask cua minh; du lieu khop tung element.
//==============================================================================
`ifndef DMA350_VSEQ_2D_TMPLT_BOTH_1D_SV
`define DMA350_VSEQ_2D_TMPLT_BOTH_1D_SV

class dma350_vseq_2d_tmplt_both_1d extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_tmplt_both_1d)

  function new(string name = "dma350_vseq_2d_tmplt_both_1d");
    super.new(name);
    src_ysize = 1;
    des_ysize = 1;
    src_xsize = 16;
    des_xsize = 16;
    srctmpltsize = 5'd7;
    srctmplt = 32'h0000_0069;
    destmpltsize = 5'd3;
    destmplt = 32'h0000_000F;
    xtype = XT_CONT;
  endfunction

endclass : dma350_vseq_2d_tmplt_both_1d

`endif // DMA350_VSEQ_2D_TMPLT_BOTH_1D_SV
