//==============================================================================
// dma350_vseq_2d_wrap_srcx_gt_desx.sv
//   GROUP B - TRM 5.3.2.2 'SRCXSIZE > DESXSIZE' + XTYPE = wrap
//   Wrap/fill khi dich hep hon: copy DUNG khi dong dich day.
//   Ky vong: moi dong dich chi nhan 6 element dau cua dong nguon tuong ung.
//==============================================================================
`ifndef DMA350_VSEQ_2D_WRAP_SRCX_GT_DESX_SV
`define DMA350_VSEQ_2D_WRAP_SRCX_GT_DESX_SV

class dma350_vseq_2d_wrap_srcx_gt_desx extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_wrap_srcx_gt_desx)

  function new(string name = "dma350_vseq_2d_wrap_srcx_gt_desx");
    super.new(name);
    src_xsize = 12;
    des_xsize = 6;
    xtype = XT_WRAP;
    src_ystride = 'h60;
    des_ystride = 'h30;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_wrap_srcx_gt_desx

`endif // DMA350_VSEQ_2D_WRAP_SRCX_GT_DESX_SV
