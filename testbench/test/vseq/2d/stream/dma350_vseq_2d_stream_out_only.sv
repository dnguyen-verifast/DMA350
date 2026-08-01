//==============================================================================
// dma350_vseq_2d_stream_out_only.sv
//   GROUP G - TRM 5.5.2 + Table 5-6, 'Stream out only' tren lenh 2D
//   Doc khoi 2D tren AXI5 roi day het ra str_out; khong ghi AXI (DESXSIZE = 0).
//   Ky vong: ca khoi 2D nam trong MOT packet stream, TLAST o beat cuoi cung.
//==============================================================================
`ifndef DMA350_VSEQ_2D_STREAM_OUT_ONLY_SV
`define DMA350_VSEQ_2D_STREAM_OUT_ONLY_SV

class dma350_vseq_2d_stream_out_only extends dma350_vseq_2d_stream_base;
  `uvm_object_utils(dma350_vseq_2d_stream_out_only)

  function new(string name = "dma350_vseq_2d_stream_out_only");
    super.new(name);
    streamtype = ST_OUT_ONLY;
    des_n = 0;
    des_ysize = 0;
    drive_in = 0;
    xtype = XT_CONT;
    ytype = YT_CONT;
  endfunction

endclass : dma350_vseq_2d_stream_out_only

`endif // DMA350_VSEQ_2D_STREAM_OUT_ONLY_SV
