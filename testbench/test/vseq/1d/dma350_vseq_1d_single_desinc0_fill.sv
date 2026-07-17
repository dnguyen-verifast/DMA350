//==============================================================================
// dma350_vseq_1d_single_desinc0_fill.sv
//   TRM 5.2.2 (List of cases for 1D WRAP) -- DESXADDRINC = 0 (FIFO dich, vi du TRM: SRC=3 DES=8)
//   XTYPE = fill
//
//   Ky vong: DESXADDRINC=0: fill value duoc ghi vao FIFO o cuoi transfer.
//==============================================================================
`ifndef DMA350_VSEQ_1D_SINGLE_DESINC0_FILL_SV
`define DMA350_VSEQ_1D_SINGLE_DESINC0_FILL_SV

class dma350_vseq_1d_single_desinc0_fill extends dma350_vseq_1d_single_base;
  `uvm_object_utils(dma350_vseq_1d_single_desinc0_fill)

  function new(string name = "dma350_vseq_1d_single_desinc0_fill");
    super.new(name);
    src_xsize       = 3;
    des_xsize       = 8;
    src_xaddrinc    = 1;
    des_xaddrinc    = 0;
    xtype           = XT_FILL;
    expect_idle     = 0;
    chk_src_drained = 0;
    chk_des_drained = 1;
  endfunction

  virtual task body();
    super.body();   // POR + responder AXI5/AXIS
    run_1d(0);
  endtask

endclass : dma350_vseq_1d_single_desinc0_fill

`endif // DMA350_VSEQ_1D_SINGLE_DESINC0_FILL_SV
