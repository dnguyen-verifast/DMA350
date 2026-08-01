//==============================================================================
// dma350_vseq_stream_in_only.sv
//   "Stream-in only" (bang anh): USESTREAM=1, STREAMTYPE=10.
//   str_in (VIP master lai 8 beat + TLAST) -> DMA ghi dich tren AXI (DESXSIZE=8).
//   KHONG doc AXI (src_n=0).
//==============================================================================
`ifndef DMA350_VSEQ_STREAM_IN_ONLY_SV
`define DMA350_VSEQ_STREAM_IN_ONLY_SV

class dma350_vseq_stream_in_only extends dma350_vseq_stream_base;
  `uvm_object_utils(dma350_vseq_stream_in_only)

  function new(string name = "dma350_vseq_stream_in_only");
    super.new(name);
    use_stream = 1;
    streamtype = ST_IN_ONLY;
    src_n      = 0;             // khong doc AXI
    des_n      = 8;
    drive_in   = 1;
    in_beats   = 8;
  endfunction

endclass : dma350_vseq_stream_in_only

`endif // DMA350_VSEQ_STREAM_IN_ONLY_SV
