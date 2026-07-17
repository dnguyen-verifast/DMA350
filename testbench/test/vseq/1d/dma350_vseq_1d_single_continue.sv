//==============================================================================
// dma350_vseq_1d_single_continue.sv
//   1D single copy, XTYPE=continue (001) : copy 16 word (64 byte)
//   0x1000 -> 0x2000 tren channel 0. Dung cfg_ch() cua base (continue mac dinh).
//==============================================================================
`ifndef DMA350_VSEQ_1D_SINGLE_CONTINUE_SV
`define DMA350_VSEQ_1D_SINGLE_CONTINUE_SV

class dma350_vseq_1d_single_continue extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_1d_single_continue)
  function new(string name="dma350_vseq_1d_single_continue"); super.new(name); endfunction

  virtual task body();
    super.body();
    cfg_ch(.ch(0), .src(32'h0000_1000), .des(32'h0000_2000), .xsize(16));
    enable_ch(0);
    wait_ch_done(0);
    clear_ch_status(0);
  endtask
endclass

`endif // DMA350_VSEQ_1D_SINGLE_CONTINUE_SV
