//==============================================================================
// dma350_vseq_cmdlink_apb_xaddrinc.sv
//   MODE_APB: descriptor cap nhat XADDRINC (buoc tang dia chi src/des khac nhau)
//   + SRCADDR/DESADDR/XSIZE. Kiem tra header co bit XADDRINC nap dung.
//     - descriptor 0 : XADDRINC | SRCADDR | DESADDR | XSIZE | LINKADDR
//     - descriptor 1 : XADDRINC | SRCADDR | DESADDR | XSIZE | LINKADDR(=0)
//==============================================================================
`ifndef DMA350_VSEQ_CMDLINK_APB_XADDRINC_SV
`define DMA350_VSEQ_CMDLINK_APB_XADDRINC_SV

class dma350_vseq_cmdlink_apb_xaddrinc extends dma350_vseq_cmdlink_base;
  `uvm_object_utils(dma350_vseq_cmdlink_apb_xaddrinc)

  function new(string name = "dma350_vseq_cmdlink_apb_xaddrinc");
    super.new(name);
    mode  = MODE_APB;
    xsize = 12;
  endfunction

  virtual function void program_descriptors();
    // src +2, des +1 (DESXADDRINC=1, SRCXADDRINC=2)
    cmd_slot(0); cmd_begin(0);
      cmd_set(HDR_XADDRINC, 32'h0001_0002);
      cmd_set(HDR_SRCADDR,  src_addr + 32'h1000);
      cmd_set(HDR_DESADDR,  des_addr + 32'h1000);
      cmd_set(HDR_XSIZE,    {16'd8, 16'd8});
      cmd_link(1);
    cmd_emit();

    // src +1, des +2
    cmd_slot(1); cmd_begin(0);
      cmd_set(HDR_XADDRINC, 32'h0002_0001);
      cmd_set(HDR_SRCADDR,  src_addr + 32'h2000);
      cmd_set(HDR_DESADDR,  des_addr + 32'h2000);
      cmd_set(HDR_XSIZE,    {16'd8, 16'd8});
      cmd_end();
    cmd_emit();
  endfunction

endclass : dma350_vseq_cmdlink_apb_xaddrinc

`endif // DMA350_VSEQ_CMDLINK_APB_XADDRINC_SV
