//==============================================================================
// dma350_vseq_cmdlink_boot_single.sv
//   MODE_BOOT (autoboot): boot_addr -> descriptor #0. DMAC tu nap lenh dau vao
//   CH0 va chay ngay sau reset. Chuoi CHI 1 lenh (LINKADDR=0 -> ket thuc).
//   Lenh boot PHAI REGCLEAR (thanh ghi o mac dinh sau reset).
//     - descriptor 0 : REGCLEAR + full 1D, LINKADDR(=0)
//==============================================================================
`ifndef DMA350_VSEQ_CMDLINK_BOOT_SINGLE_SV
`define DMA350_VSEQ_CMDLINK_BOOT_SINGLE_SV

class dma350_vseq_cmdlink_boot_single extends dma350_vseq_cmdlink_base;
  `uvm_object_utils(dma350_vseq_cmdlink_boot_single)

  function new(string name = "dma350_vseq_cmdlink_boot_single");
    super.new(name);
    mode = MODE_BOOT;
  endfunction

  virtual function void program_descriptors();
    cmd_slot(0); cmd_begin(1);                       // REGCLEAR
      cmd_set(HDR_INTREN,      32'h0000_0003);
      cmd_set(HDR_CTRL,        ctrl_1d(3'd2));        // 1D continue, word
      cmd_set(HDR_SRCADDR,     src_addr);
      cmd_set(HDR_DESADDR,     des_addr);
      cmd_set(HDR_XSIZE,       {16'd16, 16'd16});
      cmd_set(HDR_XADDRINC,    32'h0001_0001);
      cmd_set(HDR_SRCTRANSCFG, TRANSCFG_DEFAULT);
      cmd_set(HDR_DESTRANSCFG, TRANSCFG_DEFAULT);
      cmd_end();                                      // LINKADDR = 0 -> ket thuc
    cmd_emit();
  endfunction

endclass : dma350_vseq_cmdlink_boot_single

`endif // DMA350_VSEQ_CMDLINK_BOOT_SINGLE_SV
