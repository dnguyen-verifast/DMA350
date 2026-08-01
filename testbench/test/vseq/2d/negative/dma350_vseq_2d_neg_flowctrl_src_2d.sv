//==============================================================================
// dma350_vseq_2d_neg_flowctrl_src_2d.sv
//   GROUP X (AM) - TRM 5.9.2.2 'Flow control trigger input modes are only
//   supported with 1D source or destination' (RTL: flowctrl & (ysize > 1))
//   Phia NGUON dat flow-control trigger tren lenh 2D (YSIZE = 4).
//   Ky vong: STAT_ERR + ERRINFO.CFGERR/CFGCONFLERR, khong co transfer nao.
//==============================================================================
`ifndef DMA350_VSEQ_2D_NEG_FLOWCTRL_SRC_2D_SV
`define DMA350_VSEQ_2D_NEG_FLOWCTRL_SRC_2D_SV

class dma350_vseq_2d_neg_flowctrl_src_2d extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_neg_flowctrl_src_2d)

  function new(string name = "dma350_vseq_2d_neg_flowctrl_src_2d");
    super.new(name);
    expect_cfg_err = 1;
  endfunction

  virtual task cfg_2d(int c = -1);
    int cc = (c < 0) ? int'(ch) : c;
    super.cfg_2d(cc);
    // SRCTRIGINCFG : TYPE=HW(10) MODE=FLOW_DMA(10) SEL=0 BLKSIZE=3
    apb_write(ch_addr(cc,O_SRCTRIGINCFG), {8'h0, 8'd3, 4'h0, 2'b10, 2'b10, 8'd0});
    // bat CH_CTRL.USESRCTRIGIN (bit25)
    apb_write(ch_addr(cc,O_CTRL), ctrl_2d() | (32'h1 << 25));
  endtask

endclass : dma350_vseq_2d_neg_flowctrl_src_2d

`endif // DMA350_VSEQ_2D_NEG_FLOWCTRL_SRC_2D_SV
