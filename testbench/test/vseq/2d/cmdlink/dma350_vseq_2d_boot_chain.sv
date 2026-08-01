//==============================================================================
// dma350_vseq_2d_boot_chain.sv
//   GROUP H - TRM 5.7.3, autoboot roi command-link tiep tren 2D
//   Lenh boot 2D chay xong thi link sang descriptor 2D thu hai.
//   Ky vong: ca chuoi chay tu dong sau reset, khong co truy cap APB nao truoc do.
//==============================================================================
`ifndef DMA350_VSEQ_2D_BOOT_CHAIN_SV
`define DMA350_VSEQ_2D_BOOT_CHAIN_SV

class dma350_vseq_2d_boot_chain extends dma350_vseq_2d_link_base;
  `uvm_object_utils(dma350_vseq_2d_boot_chain)

  function new(string name = "dma350_vseq_2d_boot_chain");
    super.new(name);
    mode = MODE_BOOT;
  endfunction

  virtual function void program_descriptors();
    cmd_slot(0); cmd_begin(1);
      cmd_set(HDR_INTREN,      32'h0000_0003);
      cmd_set(HDR_CTRL,        ctrl_2d(transize, XT_CONT, YT_CONT));
      cmd_set(HDR_SRCADDR,     src_addr);
      cmd_set(HDR_DESADDR,     des_addr);
      cmd_set(HDR_XSIZE,       {16'd8, 16'd8});
      cmd_set(HDR_SRCTRANSCFG, TRANSCFG_DEFAULT);
      cmd_set(HDR_DESTRANSCFG, TRANSCFG_DEFAULT);
      cmd_set(HDR_XADDRINC,    32'h0001_0001);
      cmd_set(HDR_YADDRSTRIDE, ystride_word('h20, 'h20));
      cmd_set(HDR_YSIZE,       ysize_word(2, 2));
      cmd_link(1);
    cmd_emit();

    cmd_slot(1); cmd_begin(0);
      cmd_set(HDR_DESADDR, des_addr + 32'h1000);
      cmd_set(HDR_YSIZE,   ysize_word(4, 4));
      cmd_end();
    cmd_emit();
  endfunction

endclass : dma350_vseq_2d_boot_chain

`endif // DMA350_VSEQ_2D_BOOT_CHAIN_SV
