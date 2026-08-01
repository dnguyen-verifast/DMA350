//==============================================================================
// dma350_vseq_2d_boot_single.sv
//   GROUP H - TRM 5.7.3 'Automatic boot feature' voi lenh 2D
//   Autoboot nap MOT lenh 2D vao CH0 ngay sau reset (khong can APB).
//   Lenh boot dau tien PHAI dat REGCLEAR (TRM: thanh ghi ve mac dinh).
//   Ky vong: CH0 tu chay khoi 2D; ch_enabled[0] len trong suot qua trinh.
//==============================================================================
`ifndef DMA350_VSEQ_2D_BOOT_SINGLE_SV
`define DMA350_VSEQ_2D_BOOT_SINGLE_SV

class dma350_vseq_2d_boot_single extends dma350_vseq_2d_link_base;
  `uvm_object_utils(dma350_vseq_2d_boot_single)

  function new(string name = "dma350_vseq_2d_boot_single");
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
      cmd_set(HDR_YSIZE,       ysize_word(4, 4));
      cmd_end();
    cmd_emit();
  endfunction

endclass : dma350_vseq_2d_boot_single

`endif // DMA350_VSEQ_2D_BOOT_SINGLE_SV
