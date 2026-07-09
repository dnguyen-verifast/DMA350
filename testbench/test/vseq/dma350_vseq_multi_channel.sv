//==============================================================================
// dma350_vseq_multi_channel.sv
//   Multi-channel : num_ch channel copy song song, vung dia chi tach biet.
//==============================================================================
`ifndef DMA350_VSEQ_MULTI_CHANNEL_SV
`define DMA350_VSEQ_MULTI_CHANNEL_SV

class dma350_vseq_multi_channel extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_multi_channel)
  int unsigned num_ch = 4;
  function new(string name="dma350_vseq_multi_channel"); super.new(name); endfunction

  virtual task body();
    super.body();
    for (int ch = 0; ch < num_ch; ch++)
      cfg_ch_1d(.ch(ch), .src(32'h0001_0000 + ch*32'h1000),
                         .des(32'h0002_0000 + ch*32'h1000), .xsize(8));
    for (int ch = 0; ch < num_ch; ch++)
      enable_ch(ch);
    for (int ch = 0; ch < num_ch; ch++) begin
      wait_ch_done(ch);
      clear_ch_status(ch);
    end
  endtask
endclass

`endif // DMA350_VSEQ_MULTI_CHANNEL_SV
