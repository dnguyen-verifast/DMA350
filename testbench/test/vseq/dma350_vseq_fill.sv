//==============================================================================
// dma350_vseq_fill.sv
//   FILL : ghi 32 word gia tri FILLVAL, khong doc nguon (XTYPE=011).
//==============================================================================
`ifndef DMA350_VSEQ_FILL_SV
`define DMA350_VSEQ_FILL_SV

class dma350_vseq_fill extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_fill)
  function new(string name="dma350_vseq_fill"); super.new(name); endfunction

  virtual task body();
    super.body();
    apb_write(ch_addr(0,O_DESADDR),  32'h0000_3000);
    apb_write(ch_addr(0,O_DESADDRHI),32'h0);
    apb_write(ch_addr(0,O_XSIZE),    {16'd32, 16'd32});
    apb_write(ch_addr(0,O_XADDRINC), 32'h0001_0001);
    apb_write(ch_addr(0,O_FILLVAL),  32'hCAFE_F00D);
    // TRANSIZE=word, XTYPE=fill(011), DONETYPE=end-of-command
    apb_write(ch_addr(0,O_CTRL), (32'h1<<21) | (32'h3<<9) | 32'h2);
    apb_write(ch_addr(0,O_INTREN), 32'h3);
    enable_ch(0);
    wait_ch_done(0);
    clear_ch_status(0);
  endtask
endclass

`endif // DMA350_VSEQ_FILL_SV
