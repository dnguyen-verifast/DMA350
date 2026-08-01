//==============================================================================
// dma350_vseq_2d_neg_trigsel_out_of_range.sv
//   GROUP X (AM) - TRM 5.9.2.2 'Non-existent trigger resource is selected'
//   SRCTRIGINSEL tro toi cong trigger vuot NUM_TRIGGER_IN tren lenh 2D.
//   Ky vong: STAT_ERR + ERRINFO.CFGERR/REGVALERR (hoac SRCTRIGINSELERR).
//==============================================================================
`ifndef DMA350_VSEQ_2D_NEG_TRIGSEL_OUT_OF_RANGE_SV
`define DMA350_VSEQ_2D_NEG_TRIGSEL_OUT_OF_RANGE_SV

class dma350_vseq_2d_neg_trigsel_out_of_range extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_neg_trigsel_out_of_range)

  function new(string name = "dma350_vseq_2d_neg_trigsel_out_of_range");
    super.new(name);
    expect_cfg_err = 1;
  endfunction

  virtual task cfg_2d(int c = -1);
    int cc = (c < 0) ? int'(ch) : c;
    super.cfg_2d(cc);
    // TYPE=HW(10) MODE=CMD(00) SEL=200 (khong ton tai)
    apb_write(ch_addr(cc,O_SRCTRIGINCFG), {8'h0, 8'd3, 4'h0, 2'b00, 2'b10, 8'd200});
    apb_write(ch_addr(cc,O_CTRL), ctrl_2d() | (32'h1 << 25));
  endtask

endclass : dma350_vseq_2d_neg_trigsel_out_of_range

`endif // DMA350_VSEQ_2D_NEG_TRIGSEL_OUT_OF_RANGE_SV
