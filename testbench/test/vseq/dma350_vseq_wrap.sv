//==============================================================================
// dma350_vseq_wrap.sv
//   WRAP : XTYPE=wrap (010) - dia chi nguon quay vong (FIFO-style region).
//==============================================================================
`ifndef DMA350_VSEQ_WRAP_SV
`define DMA350_VSEQ_WRAP_SV

class dma350_vseq_wrap extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_wrap)
  function new(string name="dma350_vseq_wrap"); super.new(name); endfunction

  virtual task body();
    super.body();
    apb_write(ch_addr(0,O_SRCADDR),  32'h0000_6000);
    apb_write(ch_addr(0,O_SRCADDRHI),32'h0);
    apb_write(ch_addr(0,O_DESADDR),  32'h0000_7000);
    apb_write(ch_addr(0,O_DESADDRHI),32'h0);
    apb_write(ch_addr(0,O_XSIZE),    {16'd16, 16'd16});
    apb_write(ch_addr(0,O_XADDRINC), 32'h0001_0001);
    // TRANSIZE=word, XTYPE=wrap(010), DONETYPE=end-of-command
    apb_write(ch_addr(0,O_CTRL), (32'h1<<21) | (32'h2<<9) | 32'h2);
    apb_write(ch_addr(0,O_INTREN), 32'h3);
    enable_ch(0);
    wait_ch_done(0);
    clear_ch_status(0);
  endtask
endclass

`endif // DMA350_VSEQ_WRAP_SV
