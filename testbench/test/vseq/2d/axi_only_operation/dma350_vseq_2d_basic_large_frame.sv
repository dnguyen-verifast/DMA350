//==============================================================================
// dma350_vseq_2d_basic_large_frame.sv
//   GROUP A - TRM 5.3.1, khung lon de sinh nhieu burst / nhieu dong
//   Khung 16 element x 16 dong, stride 0x80 -> 16 lan start_line.
//   Ky vong: khong ro ri giua cac dong; burst khong vuot ranh gioi 1KB (TRM 6.2).
//==============================================================================
`ifndef DMA350_VSEQ_2D_BASIC_LARGE_FRAME_SV
`define DMA350_VSEQ_2D_BASIC_LARGE_FRAME_SV

class dma350_vseq_2d_basic_large_frame extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_basic_large_frame)

  function new(string name = "dma350_vseq_2d_basic_large_frame");
    super.new(name);
    src_xsize = 16;
    des_xsize = 16;
    src_ysize = 16;
    des_ysize = 16;
    src_ystride = 'h80;
    des_ystride = 'h80;
    chk_src_drained = 1;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_basic_large_frame

`endif // DMA350_VSEQ_2D_BASIC_LARGE_FRAME_SV
