//==============================================================================
// dma350_vseq_cmdlink_apb_transcfg.sv
//   MODE_APB: descriptor cap nhat SRCTRANSCFG | DESTRANSCFG (doi MAXBURSTLEN)
//   cung voi XSIZE. Kiem tra header co bit TRANSCFG nap dung (thay doi hinh
//   dang burst tren AXI).
//     - descriptor 0 : SRCTRANSCFG | DESTRANSCFG | XSIZE | LINKADDR
//     - descriptor 1 : DESADDR | XSIZE | LINKADDR(=0)
//==============================================================================
`ifndef DMA350_VSEQ_CMDLINK_APB_TRANSCFG_SV
`define DMA350_VSEQ_CMDLINK_APB_TRANSCFG_SV

class dma350_vseq_cmdlink_apb_transcfg extends dma350_vseq_cmdlink_base;
  `uvm_object_utils(dma350_vseq_cmdlink_apb_transcfg)

  // TRANSCFG voi MAXBURSTLEN khac default (NONSECATTR=1 giu nguyen o bit10)
  localparam bit [31:0] TRANSCFG_BURST4 = 32'h0003_0400;  // SRCMAXBURSTLEN=3 -> burst<=4
  localparam bit [31:0] TRANSCFG_BURST8 = 32'h0007_0400;  // DESMAXBURSTLEN=7 -> burst<=8

  function new(string name = "dma350_vseq_cmdlink_apb_transcfg");
    super.new(name);
    mode  = MODE_APB;
    xsize = 16;
  endfunction

  virtual function void program_descriptors();
    cmd_slot(0); cmd_begin(0);
      cmd_set(HDR_SRCTRANSCFG, TRANSCFG_BURST4);
      cmd_set(HDR_DESTRANSCFG, TRANSCFG_BURST8);
      cmd_set(HDR_SRCADDR,     src_addr + 32'h1000);
      cmd_set(HDR_DESADDR,     des_addr + 32'h1000);
      cmd_set(HDR_XSIZE,       {16'd16, 16'd16});
      cmd_link(1);
    cmd_emit();

    cmd_slot(1); cmd_begin(0);
      cmd_set(HDR_DESADDR, des_addr + 32'h2000);
      cmd_set(HDR_XSIZE,   {16'd6, 16'd6});
      cmd_end();
    cmd_emit();
  endfunction

endclass : dma350_vseq_cmdlink_apb_transcfg

`endif // DMA350_VSEQ_CMDLINK_APB_TRANSCFG_SV
