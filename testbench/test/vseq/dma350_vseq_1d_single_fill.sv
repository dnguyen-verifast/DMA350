//==============================================================================
// dma350_vseq_1d_single_fill.sv
//   1D single, XTYPE=fill (011) : chi GHI gia tri FILLVAL, khong doc nguon.
//   Ghi 32 word FILLVAL=0xCAFEF00D vao 0x3000 tren channel 0.
//==============================================================================
`ifndef DMA350_VSEQ_1D_SINGLE_FILL_SV
`define DMA350_VSEQ_1D_SINGLE_FILL_SV

class dma350_vseq_1d_single_fill extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_1d_single_fill)
  function new(string name="dma350_vseq_1d_single_fill"); super.new(name); endfunction

  virtual task body();
    super.body();
    apb_write(ch_addr(0,O_DESADDR),  32'h0000_3000);
    apb_write(ch_addr(0,O_DESADDRHI),32'h0);
    apb_write(ch_addr(0,O_XSIZE),    {16'd32, 16'd32});
    apb_write(ch_addr(0,O_XADDRINC), 32'h0001_0001);   // des +1 element
    apb_write(ch_addr(0,O_FILLVAL),  32'hCAFE_F00D);
    // TRANSIZE=word(010), XTYPE=fill(011), DONETYPE=end-of-command
    apb_write(ch_addr(0,O_CTRL), (32'h1<<21) | (32'h3<<9) | 32'h2);
    apb_write(ch_addr(0,O_INTREN), 32'h3);             // IE_DONE | IE_ERR
    enable_ch(0);
    wait_ch_done(0);
    clear_ch_status(0);
  endtask
endclass

`endif // DMA350_VSEQ_1D_SINGLE_FILL_SV
