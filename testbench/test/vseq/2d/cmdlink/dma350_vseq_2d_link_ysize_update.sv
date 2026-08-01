//==============================================================================
// dma350_vseq_2d_link_ysize_update.sv
//   GROUP H - TRM Table 5-12 bit 15 (HDR_YSIZE) tren command link
//   Chuoi 3 lenh, MOI lenh chi doi CH_YSIZE (so dong) va DESADDR.
//   Ky vong: cac thanh ghi khac giu nguyen; so dong moi lenh dung nhu descriptor.
//==============================================================================
`ifndef DMA350_VSEQ_2D_LINK_YSIZE_UPDATE_SV
`define DMA350_VSEQ_2D_LINK_YSIZE_UPDATE_SV

class dma350_vseq_2d_link_ysize_update extends dma350_vseq_2d_link_base;
  `uvm_object_utils(dma350_vseq_2d_link_ysize_update)

  function new(string name = "dma350_vseq_2d_link_ysize_update");
    super.new(name);
    mode = MODE_APB;
  endfunction

  virtual function void program_descriptors();
    cmd_slot(0); cmd_begin(0);
      cmd_set(HDR_DESADDR, des_addr + 32'h1000);
      cmd_set(HDR_YSIZE,   ysize_word(2, 2));
      cmd_link(1);
    cmd_emit();

    cmd_slot(1); cmd_begin(0);
      cmd_set(HDR_DESADDR, des_addr + 32'h2000);
      cmd_set(HDR_YSIZE,   ysize_word(6, 6));
      cmd_link(2);
    cmd_emit();

    cmd_slot(2); cmd_begin(0);
      cmd_set(HDR_DESADDR, des_addr + 32'h3000);
      cmd_set(HDR_YSIZE,   ysize_word(1, 1));
      cmd_end();
    cmd_emit();
  endfunction

endclass : dma350_vseq_2d_link_ysize_update

`endif // DMA350_VSEQ_2D_LINK_YSIZE_UPDATE_SV
