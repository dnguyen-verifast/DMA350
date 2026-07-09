//==============================================================================
// dma350_vseq_2d_copy.sv
//   Copy 2D : 4 dong x 8 word, stride nguon/dich 0x40 byte.
//==============================================================================
`ifndef DMA350_VSEQ_2D_COPY_SV
`define DMA350_VSEQ_2D_COPY_SV

class dma350_vseq_2d_copy extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_2d_copy)
  function new(string name="dma350_vseq_2d_copy"); super.new(name); endfunction

  virtual task body();
    super.body();
    apb_write(ch_addr(0,O_SRCADDR),    32'h0000_4000);
    apb_write(ch_addr(0,O_SRCADDRHI),  32'h0);
    apb_write(ch_addr(0,O_DESADDR),    32'h0000_5000);
    apb_write(ch_addr(0,O_DESADDRHI),  32'h0);
    apb_write(ch_addr(0,O_XSIZE),      {16'd8, 16'd8});
    apb_write(ch_addr(0,O_XADDRINC),   32'h0001_0001);
    apb_write(ch_addr(0,O_YSIZE),      32'h0000_0004);           // 4 dong
    apb_write(ch_addr(0,O_YADDRSTRIDE),{16'h0040, 16'h0040});    // des|src stride
    // TRANSIZE=word, XTYPE=cont, YTYPE=cont(2D), DONETYPE=end-of-command
    apb_write(ch_addr(0,O_CTRL), (32'h1<<21) | (32'h1<<12) | (32'h1<<9) | 32'h2);
    apb_write(ch_addr(0,O_INTREN), 32'h3);
    enable_ch(0);
    wait_ch_done(0);
    clear_ch_status(0);
  endtask
endclass

`endif // DMA350_VSEQ_2D_COPY_SV
