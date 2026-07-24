//==============================================================================
// dma350_vseq_cmdlink_apb_ctrl_only.sv
//   MODE_APB: descriptor chi update DUY NHAT thanh ghi CTRL (doi TRANSIZE) +
//   LINKADDR. Tat ca dia chi/size ke thua tu lenh APB truoc. HEADER rat gon
//   (CTRL | LINKADDR) -> kiem tra decode header toi thieu.
//     - descriptor 0 : CTRL(byte) | LINKADDR
//     - descriptor 1 : CTRL(word) | LINKADDR(=0)
//==============================================================================
`ifndef DMA350_VSEQ_CMDLINK_APB_CTRL_ONLY_SV
`define DMA350_VSEQ_CMDLINK_APB_CTRL_ONLY_SV

class dma350_vseq_cmdlink_apb_ctrl_only extends dma350_vseq_cmdlink_base;
  `uvm_object_utils(dma350_vseq_cmdlink_apb_ctrl_only)

  function new(string name = "dma350_vseq_cmdlink_apb_ctrl_only");
    super.new(name);
    mode     = MODE_APB;
    xsize    = 8;
    transize = 3'd2;                 // APB cmd0: word
  endfunction

  virtual function void program_descriptors();
    cmd_slot(0); cmd_begin(0);
      cmd_set(HDR_CTRL, ctrl_1d(3'd0));   // doi sang TRANSIZE = byte
      cmd_link(1);
    cmd_emit();

    cmd_slot(1); cmd_begin(0);
      cmd_set(HDR_CTRL, ctrl_1d(3'd1));   // doi sang TRANSIZE = halfword
      cmd_end();
    cmd_emit();
  endfunction

endclass : dma350_vseq_cmdlink_apb_ctrl_only

`endif // DMA350_VSEQ_CMDLINK_APB_CTRL_ONLY_SV
