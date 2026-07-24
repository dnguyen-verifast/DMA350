//==============================================================================
// dma350_vseq_cmdlink_apb_regclear.sv
//   MODE_APB: lenh #0 qua APB -> descriptor #0 (AXI) dung REGCLEAR de XOA het
//   cau hinh cu roi thiet lap lai HOAN TOAN mot copy khac (TRANSIZE/dia chi/size
//   deu doi). Kiem tra header co bit REGCLEAR nap dung.
//     - descriptor 0 : REGCLEAR + full 1D, link -> 1
//     - descriptor 1 : DESADDR | XSIZE | LINKADDR(=0)
//==============================================================================
`ifndef DMA350_VSEQ_CMDLINK_APB_REGCLEAR_SV
`define DMA350_VSEQ_CMDLINK_APB_REGCLEAR_SV

class dma350_vseq_cmdlink_apb_regclear extends dma350_vseq_cmdlink_base;
  `uvm_object_utils(dma350_vseq_cmdlink_apb_regclear)

  function new(string name = "dma350_vseq_cmdlink_apb_regclear");
    super.new(name);
    mode = MODE_APB;
  endfunction

  virtual function void program_descriptors();
    cmd_slot(0); cmd_begin(1);                       // REGCLEAR
      cmd_set(HDR_INTREN,      32'h0000_0003);
      cmd_set(HDR_CTRL,        ctrl_1d(3'd1));        // TRANSIZE = halfword
      cmd_set(HDR_SRCADDR,     src_addr + 32'h4000);
      cmd_set(HDR_DESADDR,     des_addr + 32'h4000);
      cmd_set(HDR_XSIZE,       {16'd10, 16'd10});
      cmd_set(HDR_XADDRINC,    32'h0001_0001);
      cmd_set(HDR_SRCTRANSCFG, TRANSCFG_DEFAULT);
      cmd_set(HDR_DESTRANSCFG, TRANSCFG_DEFAULT);
      cmd_link(1);
    cmd_emit();

    cmd_slot(1); cmd_begin(0);
      cmd_set(HDR_DESADDR, des_addr + 32'h5000);
      cmd_set(HDR_XSIZE,   {16'd5, 16'd5});
      cmd_end();
    cmd_emit();
  endfunction

endclass : dma350_vseq_cmdlink_apb_regclear

`endif // DMA350_VSEQ_CMDLINK_APB_REGCLEAR_SV
