//==============================================================================
// dma350_vseq_1d_single_src_gt_des_wrap.sv
//   TRM 5.2.2 (List of cases for 1D WRAP) -- SRCXSIZE > DESXSIZE
//   XTYPE = wrap
//
//   Ky vong: Destination khong du cho -> copy dung khi des day. Du lieu thua bi drop trong DMAC, KHONG ghi de.
//==============================================================================
`ifndef DMA350_VSEQ_1D_SINGLE_SRC_GT_DES_WRAP_SV
`define DMA350_VSEQ_1D_SINGLE_SRC_GT_DES_WRAP_SV

class dma350_vseq_1d_single_src_gt_des_wrap extends dma350_vseq_1d_single_base;
  `uvm_object_utils(dma350_vseq_1d_single_src_gt_des_wrap)

  function new(string name = "dma350_vseq_1d_single_src_gt_des_wrap");
    super.new(name);
    src_xsize       = 16;
    des_xsize       = 8;
    src_xaddrinc    = 1;
    des_xaddrinc    = 1;
    xtype           = XT_WRAP;
    expect_idle     = 0;
    chk_src_drained = 0;
    chk_des_drained = 1;
  endfunction

  virtual task body();
    super.body();   // POR + responder AXI5/AXIS
    run_1d(0);
  endtask

endclass : dma350_vseq_1d_single_src_gt_des_wrap

`endif // DMA350_VSEQ_1D_SINGLE_SRC_GT_DES_WRAP_SV
