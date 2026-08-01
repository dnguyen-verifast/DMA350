//==============================================================================
// dma350_vseq_2d_neg_xtype_fill_stream.sv
//   GROUP X (AM) - TRM Table 5-6 hang '2D Fill / bat ky YTYPE -> No'
//   XTYPE = fill + stream: stream khong bao ket thuc dong nen khong the fill phan du.
//   Ky vong: STAT_ERR + ERRINFO.CFGERR (RTL CO check: fill_en & usestream).
//==============================================================================
`ifndef DMA350_VSEQ_2D_NEG_XTYPE_FILL_STREAM_SV
`define DMA350_VSEQ_2D_NEG_XTYPE_FILL_STREAM_SV

class dma350_vseq_2d_neg_xtype_fill_stream extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_neg_xtype_fill_stream)

  function new(string name = "dma350_vseq_2d_neg_xtype_fill_stream");
    super.new(name);
    use_stream = 1;
    streamtype = 2'b00;
    xtype = XT_FILL;
    ytype = YT_CONT;
    src_xsize = 4;
    des_xsize = 8;
    expect_cfg_err = 1;
  endfunction

endclass : dma350_vseq_2d_neg_xtype_fill_stream

`endif // DMA350_VSEQ_2D_NEG_XTYPE_FILL_STREAM_SV
