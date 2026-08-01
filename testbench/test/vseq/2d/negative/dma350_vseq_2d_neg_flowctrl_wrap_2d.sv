//==============================================================================
// dma350_vseq_2d_neg_flowctrl_wrap_2d.sv
//   GROUP X (AM) - TRM 5.9.2.2 'wrap transfer types are not allowed with source
//   flow control trigger mode' (RTL: flowctrl_s & wrap_en) + rang buoc 2D.
//   Vi pham DONG THOI hai dieu kien: XTYPE = wrap va flow-control nguon tren 2D.
//   Ky vong: STAT_ERR + ERRINFO.CFGERR/CFGCONFLERR.
//==============================================================================
`ifndef DMA350_VSEQ_2D_NEG_FLOWCTRL_WRAP_2D_SV
`define DMA350_VSEQ_2D_NEG_FLOWCTRL_WRAP_2D_SV

class dma350_vseq_2d_neg_flowctrl_wrap_2d extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_neg_flowctrl_wrap_2d)

  function new(string name = "dma350_vseq_2d_neg_flowctrl_wrap_2d");
    super.new(name);
    xtype = XT_WRAP;
    src_xsize = 4;
    des_xsize = 8;
    expect_cfg_err = 1;
  endfunction

  virtual task cfg_2d(int c = -1);
    int cc = (c < 0) ? int'(ch) : c;
    super.cfg_2d(cc);
    apb_write(ch_addr(cc,O_SRCTRIGINCFG), {8'h0, 8'd3, 4'h0, 2'b10, 2'b10, 8'd0});
    apb_write(ch_addr(cc,O_CTRL), ctrl_2d() | (32'h1 << 25));
  endtask

endclass : dma350_vseq_2d_neg_flowctrl_wrap_2d

`endif // DMA350_VSEQ_2D_NEG_FLOWCTRL_WRAP_2D_SV
