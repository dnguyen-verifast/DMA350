//==============================================================================
// dma350_vseq_2d_reshape_same_area.sv
//   GROUP B - TRM 5.3.2.2 (truong hop dac biet SX*SY == DX*DY)
//   Nguon 9x8 va dich 8x9: cung dien tich nhung khac hinh dang.
//   TRM: khi n = 0 thi YTYPE vo nghia vi du lieu nguon lap day vua khit dich.
//   Ky vong: toan bo du lieu nguon nam gon trong dich, khong wrap khong fill.
//==============================================================================
`ifndef DMA350_VSEQ_2D_RESHAPE_SAME_AREA_SV
`define DMA350_VSEQ_2D_RESHAPE_SAME_AREA_SV

class dma350_vseq_2d_reshape_same_area extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_reshape_same_area)

  function new(string name = "dma350_vseq_2d_reshape_same_area");
    super.new(name);
    src_xsize = 9;
    des_xsize = 8;
    src_ysize = 8;
    des_ysize = 9;
    xtype = XT_CONT;
    ytype = YT_CONT;
    src_ystride = 'h24;
    des_ystride = 'h20;
    chk_src_drained = 1;
  endfunction

endclass : dma350_vseq_2d_reshape_same_area

`endif // DMA350_VSEQ_2D_RESHAPE_SAME_AREA_SV
