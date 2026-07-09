//==============================================================================
// dma350_vseq_gpo.sv
//   GPO : GPOEN0/GPOVAL0 + USEGPO, readback GPOREAD0; monitor sc doi chieu.
//==============================================================================
`ifndef DMA350_VSEQ_GPO_SV
`define DMA350_VSEQ_GPO_SV

class dma350_vseq_gpo extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_gpo)
  function new(string name="dma350_vseq_gpo"); super.new(name); endfunction

  virtual task body();
    super.body();

    apb_write(ch_addr(0,O_GPOEN0),  32'h0000_000F);   // GPO_WIDTH=4 build nay
    apb_write(ch_addr(0,O_GPOVAL0), 32'h0000_000A);
    apb_check(ch_addr(0,O_GPOEN0),  32'h0000_000F, 32'h0000_000F);
    apb_check(ch_addr(0,O_GPOVAL0), 32'h0000_000A, 32'h0000_000F);

    // chay 1 lenh nho voi USEGPO=1 de gpo_ch duoc lai gia tri GPOVAL0
    apb_write(ch_addr(0,O_SRCADDR),  32'h0005_0000);
    apb_write(ch_addr(0,O_SRCADDRHI),32'h0);
    apb_write(ch_addr(0,O_DESADDR),  32'h0005_4000);
    apb_write(ch_addr(0,O_DESADDRHI),32'h0);
    apb_write(ch_addr(0,O_XSIZE),    {16'd4, 16'd4});
    apb_write(ch_addr(0,O_XADDRINC), 32'h0001_0001);
    // TRANSIZE=word, XTYPE=cont, DONETYPE=end-of-cmd, USEGPO(bit28)
    apb_write(ch_addr(0,O_CTRL), (32'h1<<28) | (32'h1<<21) | (32'h1<<9) | 32'h2);
    apb_write(ch_addr(0,O_INTREN), 32'h3);
    enable_ch(0);
    wait_ch_done(0);

    // GPOREAD0 phai phan anh gia tri dang lai
    apb_check(ch_addr(0,O_GPOREAD0), 32'h0000_000A, 32'h0000_000F);
    clear_ch_status(0);
  endtask
endclass

`endif // DMA350_VSEQ_GPO_SV
