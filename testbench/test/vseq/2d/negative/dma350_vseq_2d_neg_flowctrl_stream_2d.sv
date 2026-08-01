//==============================================================================
// dma350_vseq_2d_neg_flowctrl_stream_2d.sv
//   GROUP X (AM) - TRM Table 5-7 'Any Flow control trigger + stream -> No'
//   Flow-control trigger ket hop stream tren lenh 2D (RTL: flowctrl & usestream).
//   Ky vong: STAT_ERR + ERRINFO.CFGERR/CFGCONFLERR.
//==============================================================================
`ifndef DMA350_VSEQ_2D_NEG_FLOWCTRL_STREAM_2D_SV
`define DMA350_VSEQ_2D_NEG_FLOWCTRL_STREAM_2D_SV

class dma350_vseq_2d_neg_flowctrl_stream_2d extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_neg_flowctrl_stream_2d)

  function new(string name = "dma350_vseq_2d_neg_flowctrl_stream_2d");
    super.new(name);
    use_stream = 1;
    streamtype = 2'b00;
    expect_cfg_err = 1;
  endfunction

  virtual task cfg_2d(int c = -1);
    int cc = (c < 0) ? int'(ch) : c;
    super.cfg_2d(cc);
    apb_write(ch_addr(cc,O_SRCTRIGINCFG), {8'h0, 8'd3, 4'h0, 2'b10, 2'b10, 8'd0});
    apb_write(ch_addr(cc,O_CTRL), ctrl_2d() | (32'h1 << 25));
  endtask

endclass : dma350_vseq_2d_neg_flowctrl_stream_2d

`endif // DMA350_VSEQ_2D_NEG_FLOWCTRL_STREAM_2D_SV
