//==============================================================================
// dma350_vseq_2d_stream_pkt_boundary.sv
//   GROUP G - TRM 5.5.2 'Packet boundaries on stream out interface' cho 2D
//   Khung 2D nhieu dong nhung stream out chi duoc coi la MOT packet.
//   Ky vong: chi mot TLAST o cuoi toan bo lenh, KHONG phai moi dong mot TLAST.
//==============================================================================
`ifndef DMA350_VSEQ_2D_STREAM_PKT_BOUNDARY_SV
`define DMA350_VSEQ_2D_STREAM_PKT_BOUNDARY_SV

class dma350_vseq_2d_stream_pkt_boundary extends dma350_vseq_2d_stream_base;
  `uvm_object_utils(dma350_vseq_2d_stream_pkt_boundary)

  function new(string name = "dma350_vseq_2d_stream_pkt_boundary");
    super.new(name);
    streamtype = ST_OUT_ONLY;
    des_n = 0;
    des_ysize = 0;
    drive_in = 0;
    src_ysize = 6;
    xtype = XT_CONT;
    ytype = YT_CONT;
  endfunction

endclass : dma350_vseq_2d_stream_pkt_boundary

`endif // DMA350_VSEQ_2D_STREAM_PKT_BOUNDARY_SV
