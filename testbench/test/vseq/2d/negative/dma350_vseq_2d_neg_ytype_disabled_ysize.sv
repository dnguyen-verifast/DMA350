//==============================================================================
// dma350_vseq_2d_neg_ytype_disabled_ysize.sv
//   GROUP X - TRM 5.3.2 'disable: No 2D transfer occurs, the YSIZE and
//   YADDRSTRIDE values are ignored'
//   YTYPE = disabled nhung YSIZE va YADDRSTRIDE van khac 0.
//   Ky vong (theo TRM): hai truong nay bi BO QUA, lenh chay nhu 1D thuan.
//   LUU Y RTL: nhanh 2D bat theo (ysize > 1) chu KHONG theo YTYPE -> RTL se van
//     chay 2D. Test nay lam ro su khac biet TRM/RTL, can xac nhan voi thiet ke.
//==============================================================================
`ifndef DMA350_VSEQ_2D_NEG_YTYPE_DISABLED_YSIZE_SV
`define DMA350_VSEQ_2D_NEG_YTYPE_DISABLED_YSIZE_SV

class dma350_vseq_2d_neg_ytype_disabled_ysize extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_neg_ytype_disabled_ysize)

  function new(string name = "dma350_vseq_2d_neg_ytype_disabled_ysize");
    super.new(name);
    ytype = YT_DIS;
    src_ysize = 4;
    des_ysize = 4;
    src_ystride = 'h40;
    des_ystride = 'h40;
  endfunction

endclass : dma350_vseq_2d_neg_ytype_disabled_ysize

`endif // DMA350_VSEQ_2D_NEG_YTYPE_DISABLED_YSIZE_SV
