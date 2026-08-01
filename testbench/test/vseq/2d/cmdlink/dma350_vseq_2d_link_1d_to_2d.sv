//==============================================================================
// dma350_vseq_2d_link_1d_to_2d.sv
//   GROUP H - TRM 5.7, chuyen che do giua cac lenh trong chuoi
//   Lenh #0 (APB) la 1D (YSIZE=1), descriptor tiep theo bien no thanh 2D.
//   Ky vong: DMAC chuyen tu 1D sang 2D trong cung chuoi ma khong can can thiep SW.
//==============================================================================
`ifndef DMA350_VSEQ_2D_LINK_1D_TO_2D_SV
`define DMA350_VSEQ_2D_LINK_1D_TO_2D_SV

class dma350_vseq_2d_link_1d_to_2d extends dma350_vseq_2d_link_base;
  `uvm_object_utils(dma350_vseq_2d_link_1d_to_2d)

  function new(string name = "dma350_vseq_2d_link_1d_to_2d");
    super.new(name);
    mode = MODE_APB;
    src_ysize = 1;
    des_ysize = 1;
  endfunction

  virtual function void program_descriptors();
    cmd_slot(0); cmd_begin(0);
      cmd_set(HDR_CTRL,        ctrl_2d(transize, XT_CONT, YT_CONT));
      cmd_set(HDR_DESADDR,     des_addr + 32'h1000);
      cmd_set(HDR_YADDRSTRIDE, ystride_word('h20, 'h20));
      cmd_set(HDR_YSIZE,       ysize_word(4, 4));   // 1D -> 2D
      cmd_end();
    cmd_emit();
  endfunction

endclass : dma350_vseq_2d_link_1d_to_2d

`endif // DMA350_VSEQ_2D_LINK_1D_TO_2D_SV
