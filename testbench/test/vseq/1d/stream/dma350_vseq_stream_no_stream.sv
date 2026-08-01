//==============================================================================
// dma350_vseq_stream_no_stream.sv
//   "No stream" (bang anh): USESTREAM=0 - copy mem-to-mem thuong, khong stream.
//   Lam baseline de doi chieu voi cac che do stream.
//==============================================================================
`ifndef DMA350_VSEQ_STREAM_NO_STREAM_SV
`define DMA350_VSEQ_STREAM_NO_STREAM_SV

class dma350_vseq_stream_no_stream extends dma350_vseq_stream_base;
  `uvm_object_utils(dma350_vseq_stream_no_stream)

  function new(string name = "dma350_vseq_stream_no_stream");
    super.new(name);
    use_stream = 0;
    src_n      = 8;
    des_n      = 8;
    drive_in   = 0;
  endfunction

endclass : dma350_vseq_stream_no_stream

`endif // DMA350_VSEQ_STREAM_NO_STREAM_SV
