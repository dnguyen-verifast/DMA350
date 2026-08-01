//==============================================================================
// dma350_vseq_stream_in_out.sv
//   "Stream-in + out" (bang anh): USESTREAM=1, STREAMTYPE=00.
//   DMA doc nguon AXI (SRCXSIZE=8) -> str_out; str_in (8 beat + TLAST) -> ghi
//   dich AXI (DESXSIZE=8). Ca hai stream cung hoat dong (mo hinh DPU).
//==============================================================================
`ifndef DMA350_VSEQ_STREAM_IN_OUT_SV
`define DMA350_VSEQ_STREAM_IN_OUT_SV

class dma350_vseq_stream_in_out extends dma350_vseq_stream_base;
  `uvm_object_utils(dma350_vseq_stream_in_out)

  function new(string name = "dma350_vseq_stream_in_out");
    super.new(name);
    use_stream = 1;
    streamtype = ST_IN_OUT;
    src_n      = 8;
    des_n      = 8;
    drive_in   = 1;
    in_beats   = 8;
  endfunction

endclass : dma350_vseq_stream_in_out

`endif // DMA350_VSEQ_STREAM_IN_OUT_SV
