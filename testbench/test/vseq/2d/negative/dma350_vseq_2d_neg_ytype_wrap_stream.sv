//==============================================================================
// dma350_vseq_2d_neg_ytype_wrap_stream.sv
//   GROUP X (AM) - TRM Table 5-6 hang '2D Continue/Wrap -> No'
//   YTYPE = wrap ket hop stream: du lieu stream KHONG the doc lai -> config error.
//   Ky vong: STAT_ERR + ERRINFO.CFGERR, khong co transfer nao.
//   LUU Y RTL: cfgconfl_err trong dma350_channel.sv hien CHI gom
//   (fill_en & usestream) | (wrap_en & fill_en) | (flowctrl & usestream)
//   | (flowctrl_s & wrap_en) | (flowctrl & (ysize>1))
//   -> dieu kien cua test nay CHUA duoc RTL kiem tra. Test du kien FAIL:
//   day la LO HONG RTL so voi TRM, can xac nhan voi thiet ke.
//==============================================================================
`ifndef DMA350_VSEQ_2D_NEG_YTYPE_WRAP_STREAM_SV
`define DMA350_VSEQ_2D_NEG_YTYPE_WRAP_STREAM_SV

class dma350_vseq_2d_neg_ytype_wrap_stream extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_neg_ytype_wrap_stream)

  function new(string name = "dma350_vseq_2d_neg_ytype_wrap_stream");
    super.new(name);
    use_stream = 1;
    streamtype = 2'b00;
    xtype = XT_CONT;
    ytype = YT_WRAP;
    src_ysize = 2;
    des_ysize = 4;
    expect_cfg_err = 1;
  endfunction

endclass : dma350_vseq_2d_neg_ytype_wrap_stream

`endif // DMA350_VSEQ_2D_NEG_YTYPE_WRAP_STREAM_SV
