//==============================================================================
// dma350_vseq_1d_single_wrap.sv
//   1D single, XTYPE=wrap (010) : dia chi nguon quay vong trong vung (FIFO-style).
//   16 word tu 0x6000 -> 0x7000 tren channel 0.
//==============================================================================
`ifndef DMA350_VSEQ_1D_SINGLE_WRAP_SV
`define DMA350_VSEQ_1D_SINGLE_WRAP_SV

class dma350_vseq_1d_single_wrap extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_1d_single_wrap)
  function new(string name="dma350_vseq_1d_single_wrap"); super.new(name); endfunction

  virtual task body();
    super.body();
    apb_write(ch_addr(0,O_SRCADDR),  32'h0000_6000);
    apb_write(ch_addr(0,O_SRCADDRHI),32'h0);
    apb_write(ch_addr(0,O_DESADDR),  32'h0000_7000);
    apb_write(ch_addr(0,O_DESADDRHI),32'h0);
    apb_write(ch_addr(0,O_XSIZE),    {16'd16, 16'd16});
    apb_write(ch_addr(0,O_XADDRINC), 32'h0001_0001);   // src/des +1 element
    // TRANSIZE=word(010), XTYPE=wrap(010), DONETYPE=end-of-command
    apb_write(ch_addr(0,O_CTRL), (32'h1<<21) | (32'h2<<9) | 32'h2);
    apb_write(ch_addr(0,O_INTREN), 32'h3);             // IE_DONE | IE_ERR
    enable_ch(0);
    wait_ch_done(0);
    clear_ch_status(0);
  endtask
endclass

`endif // DMA350_VSEQ_1D_SINGLE_WRAP_SV
