//==============================================================================
// dma350_vseq_cmdlink_boot_chain.sv
//   MODE_BOOT (autoboot): boot_addr -> descriptor #0 (REGCLEAR + full 1D), roi
//   command-link tiep sang descriptor #1, #2 - TAT CA nap qua AXI. Moi
//   descriptor mot HEADER khac nhau.
//     - descriptor 0 : REGCLEAR + full 1D  -> link 1
//     - descriptor 1 : CTRL(byte) | SRCADDR | DESADDR | XSIZE -> link 2
//     - descriptor 2 : DESADDR | XSIZE | LINKADDR(=0)
//==============================================================================
`ifndef DMA350_VSEQ_CMDLINK_BOOT_CHAIN_SV
`define DMA350_VSEQ_CMDLINK_BOOT_CHAIN_SV

class dma350_vseq_cmdlink_boot_chain extends dma350_vseq_cmdlink_base;
  `uvm_object_utils(dma350_vseq_cmdlink_boot_chain)

  function new(string name = "dma350_vseq_cmdlink_boot_chain");
    super.new(name);
    mode = MODE_BOOT;
  endfunction

  virtual function void program_descriptors();
    // descriptor 0: boot command day du
    cmd_slot(0); cmd_begin(1);                       // REGCLEAR
      cmd_set(HDR_INTREN,      32'h0000_0003);
      cmd_set(HDR_CTRL,        ctrl_1d(3'd2));
      cmd_set(HDR_SRCADDR,     src_addr);
      cmd_set(HDR_DESADDR,     des_addr);
      cmd_set(HDR_XSIZE,       {16'd16, 16'd16});
      cmd_set(HDR_XADDRINC,    32'h0001_0001);
      cmd_set(HDR_SRCTRANSCFG, TRANSCFG_DEFAULT);
      cmd_set(HDR_DESTRANSCFG, TRANSCFG_DEFAULT);
      cmd_link(1);
    cmd_emit();

    // descriptor 1: doi CTRL(byte) + dia chi + size
    cmd_slot(1); cmd_begin(0);
      cmd_set(HDR_CTRL,    ctrl_1d(3'd0));
      cmd_set(HDR_SRCADDR, src_addr + 32'h1000);
      cmd_set(HDR_DESADDR, des_addr + 32'h1000);
      cmd_set(HDR_XSIZE,   {16'd24, 16'd24});
      cmd_link(2);
    cmd_emit();

    // descriptor 2: chi doi DESADDR + XSIZE, ket thuc
    cmd_slot(2); cmd_begin(0);
      cmd_set(HDR_DESADDR, des_addr + 32'h2000);
      cmd_set(HDR_XSIZE,   {16'd8, 16'd8});
      cmd_end();
    cmd_emit();
  endfunction

endclass : dma350_vseq_cmdlink_boot_chain

`endif // DMA350_VSEQ_CMDLINK_BOOT_CHAIN_SV
