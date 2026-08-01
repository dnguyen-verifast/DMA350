//==============================================================================
// dma350_vseq_stream_out_only.sv
//   "Stream-out only" (bang anh): USESTREAM=1, STREAMTYPE=01.
//   DMA doc nguon tren AXI (SRCXSIZE=8) roi day ra str_out; KHONG ghi AXI (des_n=0).
//   Khong can lai str_in.
//==============================================================================
`ifndef DMA350_VSEQ_STREAM_OUT_ONLY_SV
`define DMA350_VSEQ_STREAM_OUT_ONLY_SV

class dma350_vseq_stream_out_only extends dma350_vseq_stream_base;
  `uvm_object_utils(dma350_vseq_stream_out_only)

  function new(string name = "dma350_vseq_stream_out_only");
    super.new(name);
    use_stream = 1;
    streamtype = ST_OUT_ONLY;
    src_n      = 8;
    des_n      = 0;             // khong ghi AXI
    drive_in   = 0;            // khong lai str_in
  endfunction

endclass : dma350_vseq_stream_out_only

`endif // DMA350_VSEQ_STREAM_OUT_ONLY_SV
