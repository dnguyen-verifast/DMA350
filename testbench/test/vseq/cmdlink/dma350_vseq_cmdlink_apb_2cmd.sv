//==============================================================================
// dma350_vseq_cmdlink_apb_2cmd.sv
//   MODE_APB: lenh #0 cau hinh qua APB -> link -> descriptor #0 (AXI).
//   Chuoi 2 lenh nap qua AXI, HEADER toi gian (khac nhau):
//     - descriptor 0 : CTRL | SRCADDR | DESADDR | XSIZE | LINKADDR
//     - descriptor 1 : DESADDR | XSIZE | LINKADDR(=0)  (ke thua reg con lai)
//==============================================================================
`ifndef DMA350_VSEQ_CMDLINK_APB_2CMD_SV
`define DMA350_VSEQ_CMDLINK_APB_2CMD_SV

class dma350_vseq_cmdlink_apb_2cmd extends dma350_vseq_cmdlink_base;
  `uvm_object_utils(dma350_vseq_cmdlink_apb_2cmd)

  function new(string name = "dma350_vseq_cmdlink_apb_2cmd");
    super.new(name);
    mode     = MODE_APB;
    xsize    = 16;
    transize = 3'd2;              // word
  endfunction

  virtual function void program_descriptors();
    cmd_slot(0); cmd_begin(0);
      cmd_set(HDR_CTRL,    ctrl_1d(transize));
      cmd_set(HDR_SRCADDR, src_addr + 32'h1000);
      cmd_set(HDR_DESADDR, des_addr + 32'h1000);
      cmd_set(HDR_XSIZE,   {16'd12, 16'd12});
      cmd_link(1);
    cmd_emit();

    cmd_slot(1); cmd_begin(0);
      cmd_set(HDR_DESADDR, des_addr + 32'h2000);
      cmd_set(HDR_XSIZE,   {16'd6, 16'd6});
      cmd_end();
    cmd_emit();
  endfunction

  virtual task body();
    super.body();
  endtask

endclass : dma350_vseq_cmdlink_apb_2cmd

`endif // DMA350_VSEQ_CMDLINK_APB_2CMD_SV
