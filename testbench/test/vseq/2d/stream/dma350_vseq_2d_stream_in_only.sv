//==============================================================================
// dma350_vseq_2d_stream_in_only.sv
//   GROUP G - TRM 5.5.1 + Table 5-6, 'Stream in only' tren lenh 2D
//   Vung dich 2D duoc do bang du lieu den tu str_in; khong doc AXI (SRCXSIZE = 0).
//   Ky vong: TLAST tren str_in ket thuc lenh; ranh gioi dong tuan theo stride.
//==============================================================================
`ifndef DMA350_VSEQ_2D_STREAM_IN_ONLY_SV
`define DMA350_VSEQ_2D_STREAM_IN_ONLY_SV

class dma350_vseq_2d_stream_in_only extends dma350_vseq_2d_stream_base;
  `uvm_object_utils(dma350_vseq_2d_stream_in_only)

  function new(string name = "dma350_vseq_2d_stream_in_only");
    super.new(name);
    streamtype = ST_IN_ONLY;
    src_n = 0;
    src_ysize = 0;
    drive_in = 1;
    in_beats = 32;
    xtype = XT_CONT;
    ytype = YT_CONT;
  endfunction

endclass : dma350_vseq_2d_stream_in_only

`endif // DMA350_VSEQ_2D_STREAM_IN_ONLY_SV
