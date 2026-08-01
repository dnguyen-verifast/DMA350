//==============================================================================
// dma350_vseq_2d_stream_no_stream.sv
//   GROUP G - TRM Table 5-6, moc so sanh: 2D KHONG dung stream
//   USESTREAM = 0 -> copy 2D mem-to-mem thuong tren cung cau hinh hinh hoc.
//   Ky vong: khong co giao dich nao tren str_in/str_out.
//==============================================================================
`ifndef DMA350_VSEQ_2D_STREAM_NO_STREAM_SV
`define DMA350_VSEQ_2D_STREAM_NO_STREAM_SV

class dma350_vseq_2d_stream_no_stream extends dma350_vseq_2d_stream_base;
  `uvm_object_utils(dma350_vseq_2d_stream_no_stream)

  function new(string name = "dma350_vseq_2d_stream_no_stream");
    super.new(name);
    use_stream = 0;
    drive_in = 0;
    xtype = XT_CONT;
    ytype = YT_CONT;
  endfunction

endclass : dma350_vseq_2d_stream_no_stream

`endif // DMA350_VSEQ_2D_STREAM_NO_STREAM_SV
