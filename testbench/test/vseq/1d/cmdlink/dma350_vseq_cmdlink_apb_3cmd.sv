//==============================================================================
// dma350_vseq_cmdlink_apb_3cmd.sv
//   MODE_APB: lenh #0 qua APB -> chuoi 3 lenh nap qua AXI (giong vi du TRM
//   Table 5-13/14/15). Moi descriptor mot HEADER khac nhau:
//     - descriptor 0 : REGCLEAR + full 1D  (0x4000_0D5D style)
//     - descriptor 1 : CTRL | SRCADDR | DESADDR | XSIZE | LINKADDR
//     - descriptor 2 : DESADDR | XSIZE | LINKADDR(=0)
//==============================================================================
`ifndef DMA350_VSEQ_CMDLINK_APB_3CMD_SV
`define DMA350_VSEQ_CMDLINK_APB_3CMD_SV

class dma350_vseq_cmdlink_apb_3cmd extends dma350_vseq_cmdlink_base;
  `uvm_object_utils(dma350_vseq_cmdlink_apb_3cmd)

  function new(string name = "dma350_vseq_cmdlink_apb_3cmd");
    super.new(name);
    mode = MODE_APB;
  endfunction

  virtual function void program_descriptors();
    // descriptor 0: REGCLEAR + thiet lap day du mot copy 1D word
    cmd_slot(0); cmd_begin(1);
      cmd_set(HDR_INTREN,      32'h0000_0001);
      cmd_set(HDR_CTRL,        ctrl_1d(3'd2));
      cmd_set(HDR_SRCADDR,     src_addr + 32'h1000);
      cmd_set(HDR_DESADDR,     des_addr + 32'h1000);
      cmd_set(HDR_XSIZE,       {16'd16, 16'd16});
      cmd_set(HDR_SRCTRANSCFG, TRANSCFG_DEFAULT);
      cmd_set(HDR_DESTRANSCFG, TRANSCFG_DEFAULT);
      cmd_link(1);
    cmd_emit();

    // descriptor 1: doi CTRL(byte) + dia chi + XSIZE
    cmd_slot(1); cmd_begin(0);
      cmd_set(HDR_CTRL,    ctrl_1d(3'd0));           // TRANSIZE = byte
      cmd_set(HDR_SRCADDR, src_addr + 32'h2000);
      cmd_set(HDR_DESADDR, des_addr + 32'h2000);
      cmd_set(HDR_XSIZE,   {16'd32, 16'd32});
      cmd_link(2);
    cmd_emit();

    // descriptor 2: chi doi DESADDR + XSIZE, ket thuc
    cmd_slot(2); cmd_begin(0);
      cmd_set(HDR_DESADDR, des_addr + 32'h3000);
      cmd_set(HDR_XSIZE,   {16'd8, 16'd8});
      cmd_end();
    cmd_emit();
  endfunction

endclass : dma350_vseq_cmdlink_apb_3cmd

`endif // DMA350_VSEQ_CMDLINK_APB_3CMD_SV
