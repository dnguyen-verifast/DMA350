//==============================================================================
// dma350_vseq_2d_wrap_srcy_gt_desy.sv
//   GROUP B - TRM 5.3.2.2 'SRCYSIZE > DESYSIZE'
//   Vung dich thap hon vung nguon (6 dong -> 3 dong).
//   Ky vong: copy dung khi vung dich day, KHONG ghi de ra ngoai; du lieu thua bi bo.
//==============================================================================
`ifndef DMA350_VSEQ_2D_WRAP_SRCY_GT_DESY_SV
`define DMA350_VSEQ_2D_WRAP_SRCY_GT_DESY_SV

class dma350_vseq_2d_wrap_srcy_gt_desy extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_wrap_srcy_gt_desy)

  function new(string name = "dma350_vseq_2d_wrap_srcy_gt_desy");
    super.new(name);
    src_ysize = 6;
    des_ysize = 3;
    ytype = YT_WRAP;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_wrap_srcy_gt_desy

`endif // DMA350_VSEQ_2D_WRAP_SRCY_GT_DESY_SV
