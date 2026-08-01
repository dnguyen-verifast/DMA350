//==============================================================================
// dma350_vseq_2d_cont_srcx_gt_desx.sv
//   GROUP B - TRM 5.3.2.2 'SRCXSIZE > DESXSIZE' + XTYPE = continue
//   Dong nguon rong hon dong dich -> phan du chay tiep sang dong dich ke tiep.
//   Ky vong: du lieu duoc dinh hinh lai lien tuc; vai beat cuoi khong vua thi bi bo.
//==============================================================================
`ifndef DMA350_VSEQ_2D_CONT_SRCX_GT_DESX_SV
`define DMA350_VSEQ_2D_CONT_SRCX_GT_DESX_SV

class dma350_vseq_2d_cont_srcx_gt_desx extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_cont_srcx_gt_desx)

  function new(string name = "dma350_vseq_2d_cont_srcx_gt_desx");
    super.new(name);
    src_xsize = 12;
    des_xsize = 6;
    xtype = XT_CONT;
    src_ystride = 'h60;
    des_ystride = 'h30;
  endfunction

endclass : dma350_vseq_2d_cont_srcx_gt_desx

`endif // DMA350_VSEQ_2D_CONT_SRCX_GT_DESX_SV
