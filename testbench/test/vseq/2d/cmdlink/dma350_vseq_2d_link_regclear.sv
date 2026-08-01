//==============================================================================
// dma350_vseq_2d_link_regclear.sv
//   GROUP H - TRM 5.7.1 'REGCLEAR' tren chuoi 2D
//   Descriptor dat bit REGCLEAR -> xoa toan bo thanh ghi 2D truoc khi nap gia tri moi.
//   Ky vong: YSIZE/YADDRSTRIDE cu KHONG con hieu luc; lenh sau la 2D hoan toan moi.
//==============================================================================
`ifndef DMA350_VSEQ_2D_LINK_REGCLEAR_SV
`define DMA350_VSEQ_2D_LINK_REGCLEAR_SV

class dma350_vseq_2d_link_regclear extends dma350_vseq_2d_link_base;
  `uvm_object_utils(dma350_vseq_2d_link_regclear)

  function new(string name = "dma350_vseq_2d_link_regclear");
    super.new(name);
    mode = MODE_APB;
  endfunction

  virtual function void program_descriptors();
    // Lenh 0: REGCLEAR -> phai nap lai DAY DU moi truong 2D
    cmd_slot(0); cmd_begin(1);
      cmd_set(HDR_INTREN,      32'h0000_0003);
      cmd_set(HDR_CTRL,        ctrl_2d(transize, XT_CONT, YT_CONT));
      cmd_set(HDR_SRCADDR,     src_addr + 32'h1000);
      cmd_set(HDR_DESADDR,     des_addr + 32'h1000);
      cmd_set(HDR_XSIZE,       {16'd4, 16'd4});
      cmd_set(HDR_SRCTRANSCFG, TRANSCFG_DEFAULT);
      cmd_set(HDR_DESTRANSCFG, TRANSCFG_DEFAULT);
      cmd_set(HDR_XADDRINC,    32'h0001_0001);
      cmd_set(HDR_YADDRSTRIDE, ystride_word('h20, 'h20));
      cmd_set(HDR_YSIZE,       ysize_word(3, 3));
      cmd_end();
    cmd_emit();
  endfunction

endclass : dma350_vseq_2d_link_regclear

`endif // DMA350_VSEQ_2D_LINK_REGCLEAR_SV
