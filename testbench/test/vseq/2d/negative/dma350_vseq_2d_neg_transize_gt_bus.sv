//==============================================================================
// dma350_vseq_2d_neg_transize_gt_bus.sv
//   GROUP X (AM) - TRM 5.9.2.2 'TRANSIZE is set to be greater than the bus width'
//   TRANSIZE = 111 (1024-bit) vuot do rong bus tren mot lenh 2D.
//   Ky vong: STAT_ERR + ERRINFO.CFGERR va REGVALERR; khong co transfer nao.
//==============================================================================
`ifndef DMA350_VSEQ_2D_NEG_TRANSIZE_GT_BUS_SV
`define DMA350_VSEQ_2D_NEG_TRANSIZE_GT_BUS_SV

class dma350_vseq_2d_neg_transize_gt_bus extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_neg_transize_gt_bus)

  function new(string name = "dma350_vseq_2d_neg_transize_gt_bus");
    super.new(name);
    transize = 3'd7;
    expect_cfg_err = 1;
  endfunction

endclass : dma350_vseq_2d_neg_transize_gt_bus

`endif // DMA350_VSEQ_2D_NEG_TRANSIZE_GT_BUS_SV
