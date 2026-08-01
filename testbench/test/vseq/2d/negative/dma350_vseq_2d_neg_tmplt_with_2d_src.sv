//==============================================================================
// dma350_vseq_2d_neg_tmplt_with_2d_src.sv
//   GROUP X (AM) - TRM 5.9.2.2 'Templated transfers are not allowed with 2D
//   transfer types' : YTYPE != disable va SRCTMPLTSIZE != 0.
//   Ky vong: STAT_ERR + ERRINFO.CFGERR/CFGCONFLERR.
//   LUU Y RTL: cfgconfl_err trong dma350_channel.sv hien CHI gom
//   (fill_en & usestream) | (wrap_en & fill_en) | (flowctrl & usestream)
//   | (flowctrl_s & wrap_en) | (flowctrl & (ysize>1))
//   -> dieu kien cua test nay CHUA duoc RTL kiem tra. Test du kien FAIL:
//   day la LO HONG RTL so voi TRM, can xac nhan voi thiet ke.
//==============================================================================
`ifndef DMA350_VSEQ_2D_NEG_TMPLT_WITH_2D_SRC_SV
`define DMA350_VSEQ_2D_NEG_TMPLT_WITH_2D_SRC_SV

class dma350_vseq_2d_neg_tmplt_with_2d_src extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_neg_tmplt_with_2d_src)

  function new(string name = "dma350_vseq_2d_neg_tmplt_with_2d_src");
    super.new(name);
    ytype = YT_CONT;
    src_ysize = 4;
    des_ysize = 4;
    srctmpltsize = 5'd7;
    srctmplt = 32'h0000_0069;
    expect_cfg_err = 1;
  endfunction

endclass : dma350_vseq_2d_neg_tmplt_with_2d_src

`endif // DMA350_VSEQ_2D_NEG_TMPLT_WITH_2D_SRC_SV
