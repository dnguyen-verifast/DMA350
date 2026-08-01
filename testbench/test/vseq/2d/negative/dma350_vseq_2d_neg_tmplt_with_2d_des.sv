//==============================================================================
// dma350_vseq_2d_neg_tmplt_with_2d_des.sv
//   GROUP X (AM) - TRM 5.9.2.2, template PHIA DICH tren lenh 2D
//   YTYPE != disable va DESTMPLTSIZE != 0 -> to hop bi cam.
//   Ky vong: STAT_ERR + ERRINFO.CFGERR/CFGCONFLERR.
//   LUU Y RTL: cfgconfl_err trong dma350_channel.sv hien CHI gom
//   (fill_en & usestream) | (wrap_en & fill_en) | (flowctrl & usestream)
//   | (flowctrl_s & wrap_en) | (flowctrl & (ysize>1))
//   -> dieu kien cua test nay CHUA duoc RTL kiem tra. Test du kien FAIL:
//   day la LO HONG RTL so voi TRM, can xac nhan voi thiet ke.
//==============================================================================
`ifndef DMA350_VSEQ_2D_NEG_TMPLT_WITH_2D_DES_SV
`define DMA350_VSEQ_2D_NEG_TMPLT_WITH_2D_DES_SV

class dma350_vseq_2d_neg_tmplt_with_2d_des extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_neg_tmplt_with_2d_des)

  function new(string name = "dma350_vseq_2d_neg_tmplt_with_2d_des");
    super.new(name);
    ytype = YT_CONT;
    src_ysize = 4;
    des_ysize = 4;
    destmpltsize = 5'd3;
    destmplt = 32'h0000_000F;
    expect_cfg_err = 1;
  endfunction

endclass : dma350_vseq_2d_neg_tmplt_with_2d_des

`endif // DMA350_VSEQ_2D_NEG_TMPLT_WITH_2D_DES_SV
