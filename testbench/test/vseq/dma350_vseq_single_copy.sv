//==============================================================================
// dma350_vseq_single_copy.sv
//   Copy 1D : 16 word (64 byte) tu 0x1000 -> 0x2000, channel 0.
//==============================================================================
`ifndef DMA350_VSEQ_SINGLE_COPY_SV
`define DMA350_VSEQ_SINGLE_COPY_SV

class dma350_vseq_single_copy extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_single_copy)
  function new(string name="dma350_vseq_single_copy"); super.new(name); endfunction

  virtual task body();
    super.body();
    cfg_ch_1d(.ch(0), .src(32'h0000_1000), .des(32'h0000_2000), .xsize(16));
    enable_ch(0);
    wait_ch_done(0);
    clear_ch_status(0);
  endtask
endclass

`endif // DMA350_VSEQ_SINGLE_COPY_SV
