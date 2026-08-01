//==============================================================================
// dma350_vseq_1d_single_srcgt_des0_fill.sv
//   TRM 5.2.2 (List of cases for 1D WRAP) -- SRCXSIZE > 0, DESXSIZE == 0
//   XTYPE = fill
//
//   Ky vong: Khong co write; chi SRCXSIZE read duoc phat (thuong dung voi stream output).
//==============================================================================
`ifndef DMA350_VSEQ_1D_SINGLE_SRCGT_DES0_FILL_SV
`define DMA350_VSEQ_1D_SINGLE_SRCGT_DES0_FILL_SV

class dma350_vseq_1d_single_srcgt_des0_fill extends dma350_vseq_1d_single_base;
  `uvm_object_utils(dma350_vseq_1d_single_srcgt_des0_fill)

  function new(string name = "dma350_vseq_1d_single_srcgt_des0_fill");
    super.new(name);
    src_xsize       = 16;
    des_xsize       = 0;
    src_xaddrinc    = 1;
    des_xaddrinc    = 1;
    xtype           = XT_FILL;
    expect_idle     = 0;
    chk_src_drained = 1;
    chk_des_drained = 0;
  endfunction

  virtual task body();
    super.body();   // POR + responder AXI5/AXIS
    run_1d(0);
  endtask

endclass : dma350_vseq_1d_single_srcgt_des0_fill

`endif // DMA350_VSEQ_1D_SINGLE_SRCGT_DES0_FILL_SV
