//==============================================================================
// dma350_vseq_2d_stream_in_out.sv
//   GROUP G - TRM 5.5 + Table 5-6, stream hai chieu tren lenh 2D
//   Doc AXI -> str_out, engine ngoai xu ly, str_in -> ghi AXI, tat ca theo hinh 2D.
//   Ky vong: ca hai giao dien deu hoat dong; ranh gioi packet nhat quan hai chieu.
//==============================================================================
`ifndef DMA350_VSEQ_2D_STREAM_IN_OUT_SV
`define DMA350_VSEQ_2D_STREAM_IN_OUT_SV

class dma350_vseq_2d_stream_in_out extends dma350_vseq_2d_stream_base;
  `uvm_object_utils(dma350_vseq_2d_stream_in_out)

  function new(string name = "dma350_vseq_2d_stream_in_out");
    super.new(name);
    streamtype = ST_IN_OUT;
    drive_in = 1;
    in_beats = 32;
    xtype = XT_CONT;
    ytype = YT_CONT;
  endfunction

endclass : dma350_vseq_2d_stream_in_out

`endif // DMA350_VSEQ_2D_STREAM_IN_OUT_SV
