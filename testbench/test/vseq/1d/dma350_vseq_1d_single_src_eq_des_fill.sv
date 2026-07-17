//==============================================================================
// dma350_vseq_1d_single_src_eq_des_fill.sv
//   TRM 5.2.2 (List of cases for 1D WRAP) -- SRCXSIZE == DESXSIZE
//   XTYPE = fill
//
//   Ky vong: Hoat dong 1D binh thuong, bat ke XTYPE.
//==============================================================================
`ifndef DMA350_VSEQ_1D_SINGLE_SRC_EQ_DES_FILL_SV
`define DMA350_VSEQ_1D_SINGLE_SRC_EQ_DES_FILL_SV

class dma350_vseq_1d_single_src_eq_des_fill extends dma350_vseq_1d_single_base;
  `uvm_object_utils(dma350_vseq_1d_single_src_eq_des_fill)

  function new(string name = "dma350_vseq_1d_single_src_eq_des_fill");
    super.new(name);
    src_xsize       = 16;
    des_xsize       = 16;
    src_xaddrinc    = 1;
    des_xaddrinc    = 1;
    xtype           = XT_FILL;
    expect_idle     = 0;
    chk_src_drained = 1;
    chk_des_drained = 1;
  endfunction

  virtual task body();
    super.body();   // POR + responder AXI5/AXIS
    run_1d(0);
  endtask

endclass : dma350_vseq_1d_single_src_eq_des_fill

`endif // DMA350_VSEQ_1D_SINGLE_SRC_EQ_DES_FILL_SV
