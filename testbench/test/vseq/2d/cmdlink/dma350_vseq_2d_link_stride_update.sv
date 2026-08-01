//==============================================================================
// dma350_vseq_2d_link_stride_update.sv
//   GROUP H - TRM Table 5-12 bit 13 (HDR_YADDRSTRIDE) tren command link
//   Chuoi 2 lenh, moi lenh doi stride (co ca stride AM) ma khong doi gi khac.
//   Ky vong: huong duyet dong thay doi dung theo tung descriptor.
//==============================================================================
`ifndef DMA350_VSEQ_2D_LINK_STRIDE_UPDATE_SV
`define DMA350_VSEQ_2D_LINK_STRIDE_UPDATE_SV

class dma350_vseq_2d_link_stride_update extends dma350_vseq_2d_link_base;
  `uvm_object_utils(dma350_vseq_2d_link_stride_update)

  function new(string name = "dma350_vseq_2d_link_stride_update");
    super.new(name);
    mode = MODE_APB;
  endfunction

  virtual function void program_descriptors();
    cmd_slot(0); cmd_begin(0);
      cmd_set(HDR_DESADDR,     des_addr + 32'h1000);
      cmd_set(HDR_YADDRSTRIDE, ystride_word('h40, 'h80));
      cmd_link(1);
    cmd_emit();

    cmd_slot(1); cmd_begin(0);
      cmd_set(HDR_DESADDR,     des_addr + 32'h20C0);
      cmd_set(HDR_YADDRSTRIDE, ystride_word('h40, -'h40));   // dich duyet nguoc
      cmd_end();
    cmd_emit();
  endfunction

endclass : dma350_vseq_2d_link_stride_update

`endif // DMA350_VSEQ_2D_LINK_STRIDE_UPDATE_SV
