//==============================================================================
// dma350_vseq_2d_neg_flowctrl_des_2d.sv
//   GROUP X (AM) - TRM 5.9.2.2, phia DICH dat flow-control trigger tren lenh 2D
//   DESTRIGINMODE = flow control trong khi DESYSIZE = 4 (> 1).
//   Ky vong: STAT_ERR + ERRINFO.CFGERR/CFGCONFLERR.
//==============================================================================
`ifndef DMA350_VSEQ_2D_NEG_FLOWCTRL_DES_2D_SV
`define DMA350_VSEQ_2D_NEG_FLOWCTRL_DES_2D_SV

class dma350_vseq_2d_neg_flowctrl_des_2d extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_neg_flowctrl_des_2d)

  function new(string name = "dma350_vseq_2d_neg_flowctrl_des_2d");
    super.new(name);
    expect_cfg_err = 1;
  endfunction

  virtual task cfg_2d(int c = -1);
    int cc = (c < 0) ? int'(ch) : c;
    super.cfg_2d(cc);
    // DESTRIGINCFG : TYPE=HW(10) MODE=FLOW_PERI(11) SEL=1 BLKSIZE=3
    apb_write(ch_addr(cc,O_DESTRIGINCFG), {8'h0, 8'd3, 4'h0, 2'b11, 2'b10, 8'd1});
    apb_write(ch_addr(cc,O_CTRL), ctrl_2d() | (32'h1 << 26));   // USEDESTRIGIN
  endtask

endclass : dma350_vseq_2d_neg_flowctrl_des_2d

`endif // DMA350_VSEQ_2D_NEG_FLOWCTRL_DES_2D_SV
