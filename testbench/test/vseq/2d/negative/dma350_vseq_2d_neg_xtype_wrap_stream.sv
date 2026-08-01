//==============================================================================
// dma350_vseq_2d_neg_xtype_wrap_stream.sv
//   GROUP X (AM) - TRM Table 5-6 hang '2D Wrap / bat ky YTYPE -> No'
//   XTYPE = wrap tren lenh 2D co stream -> config error.
//   Ky vong: STAT_ERR + ERRINFO.CFGERR, khong co transfer nao.
//   LUU Y RTL: cfgconfl_err trong dma350_channel.sv hien CHI gom
//   (fill_en & usestream) | (wrap_en & fill_en) | (flowctrl & usestream)
//   | (flowctrl_s & wrap_en) | (flowctrl & (ysize>1))
//   -> dieu kien cua test nay CHUA duoc RTL kiem tra. Test du kien FAIL:
//   day la LO HONG RTL so voi TRM, can xac nhan voi thiet ke.
//==============================================================================
`ifndef DMA350_VSEQ_2D_NEG_XTYPE_WRAP_STREAM_SV
`define DMA350_VSEQ_2D_NEG_XTYPE_WRAP_STREAM_SV

class dma350_vseq_2d_neg_xtype_wrap_stream extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_neg_xtype_wrap_stream)

  function new(string name = "dma350_vseq_2d_neg_xtype_wrap_stream");
    super.new(name);
    use_stream = 1;
    streamtype = 2'b00;
    xtype = XT_WRAP;
    ytype = YT_CONT;
    src_xsize = 4;
    des_xsize = 8;
    expect_cfg_err = 1;
  endfunction

endclass : dma350_vseq_2d_neg_xtype_wrap_stream

`endif // DMA350_VSEQ_2D_NEG_XTYPE_WRAP_STREAM_SV
