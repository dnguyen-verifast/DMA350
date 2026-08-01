//==============================================================================
// dma350_vseq_cmdlink_apb_addr_size.sv
//   MODE_APB: cac descriptor cap nhat SRCADDR | DESADDR | XSIZE | LINKADDR
//   (khong doi CTRL/TRANSCFG). Header dang "reload dia chi + so luong".
//     - descriptor 0/1 : SRCADDR | DESADDR | XSIZE | LINKADDR
//     - descriptor 2   : SRCADDR | DESADDR | XSIZE | LINKADDR(=0)
//==============================================================================
`ifndef DMA350_VSEQ_CMDLINK_APB_ADDR_SIZE_SV
`define DMA350_VSEQ_CMDLINK_APB_ADDR_SIZE_SV

class dma350_vseq_cmdlink_apb_addr_size extends dma350_vseq_cmdlink_base;
  `uvm_object_utils(dma350_vseq_cmdlink_apb_addr_size)

  function new(string name = "dma350_vseq_cmdlink_apb_addr_size");
    super.new(name);
    mode = MODE_APB;
  endfunction

  virtual function void program_descriptors();
    cmd_slot(0); cmd_begin(0);
      cmd_set(HDR_SRCADDR, src_addr + 32'h1000);
      cmd_set(HDR_DESADDR, des_addr + 32'h1000);
      cmd_set(HDR_XSIZE,   {16'd20, 16'd20});
      cmd_link(1);
    cmd_emit();

    cmd_slot(1); cmd_begin(0);
      cmd_set(HDR_SRCADDR, src_addr + 32'h2000);
      cmd_set(HDR_DESADDR, des_addr + 32'h2000);
      cmd_set(HDR_XSIZE,   {16'd14, 16'd14});
      cmd_link(2);
    cmd_emit();

    cmd_slot(2); cmd_begin(0);
      cmd_set(HDR_SRCADDR, src_addr + 32'h3000);
      cmd_set(HDR_DESADDR, des_addr + 32'h3000);
      cmd_set(HDR_XSIZE,   {16'd9, 16'd9});
      cmd_end();
    cmd_emit();
  endfunction

endclass : dma350_vseq_cmdlink_apb_addr_size

`endif // DMA350_VSEQ_CMDLINK_APB_ADDR_SIZE_SV
