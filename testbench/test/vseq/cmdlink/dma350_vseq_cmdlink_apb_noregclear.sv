//==============================================================================
// dma350_vseq_cmdlink_apb_noregclear.sv
//   MODE_APB: lenh #0 qua APB thiet lap day du. Cac descriptor sau KHONG
//   REGCLEAR, chi doi DESADDR + XSIZE -> KE THUA CTRL/SRCADDR/TRANSCFG tu lenh
//   truoc. Kiem tra "cap nhat mot phan" (partial update) nap dung.
//     - descriptor 0 : DESADDR | XSIZE | LINKADDR
//     - descriptor 1 : DESADDR | XSIZE | LINKADDR
//     - descriptor 2 : DESADDR | XSIZE | LINKADDR(=0)
//==============================================================================
`ifndef DMA350_VSEQ_CMDLINK_APB_NOREGCLEAR_SV
`define DMA350_VSEQ_CMDLINK_APB_NOREGCLEAR_SV

class dma350_vseq_cmdlink_apb_noregclear extends dma350_vseq_cmdlink_base;
  `uvm_object_utils(dma350_vseq_cmdlink_apb_noregclear)

  function new(string name = "dma350_vseq_cmdlink_apb_noregclear");
    super.new(name);
    mode  = MODE_APB;
    xsize = 16;
  endfunction

  virtual function void program_descriptors();
    // Moi lenh chi doi vung dich va so luong; nguon giu nguyen tu APB cmd0.
    cmd_slot(0); cmd_begin(0);
      cmd_set(HDR_DESADDR, des_addr + 32'h1000);
      cmd_set(HDR_XSIZE,   {16'd16, 16'd16});
      cmd_link(1);
    cmd_emit();

    cmd_slot(1); cmd_begin(0);
      cmd_set(HDR_DESADDR, des_addr + 32'h2000);
      cmd_set(HDR_XSIZE,   {16'd16, 16'd16});
      cmd_link(2);
    cmd_emit();

    cmd_slot(2); cmd_begin(0);
      cmd_set(HDR_DESADDR, des_addr + 32'h3000);
      cmd_set(HDR_XSIZE,   {16'd16, 16'd16});
      cmd_end();
    cmd_emit();
  endfunction

endclass : dma350_vseq_cmdlink_apb_noregclear

`endif // DMA350_VSEQ_CMDLINK_APB_NOREGCLEAR_SV
