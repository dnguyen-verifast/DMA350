//==============================================================================
// dma350_vseq_cmdlink_apb_example.sv
//   MODE_APB: dung TRUC TIEP anh vi du 3-lenh co san trong
//   dma350_cmdlink_mem_pkg (cmdlink_image / CMD0..CMD2, Table 5-13/14/15 cua TRM).
//   Lenh #0 cau hinh qua APB -> CH_LINKADDR = cmdlink_start_linkaddr() (CMD0_ADDR)
//   -> DMAC nap CMD0 (REGCLEAR full) -> CMD1 -> CMD2 (het), tat ca qua AXI.
//
//   Muc dich: kiem chung bo params/anh/helper CO SAN cua package nap dung.
//==============================================================================
`ifndef DMA350_VSEQ_CMDLINK_APB_EXAMPLE_SV
`define DMA350_VSEQ_CMDLINK_APB_EXAMPLE_SV

class dma350_vseq_cmdlink_apb_example extends dma350_vseq_cmdlink_base;
  `uvm_object_utils(dma350_vseq_cmdlink_apb_example)

  function new(string name = "dma350_vseq_cmdlink_apb_example");
    super.new(name);
    mode = MODE_APB;
  endfunction

  // Thay vi tu xay, NAP thang anh vi du co san (CMD0@0x2000, CMD1@0x2024, CMD2@0x203C).
  virtual function void program_descriptors();
    cmdlink_mem_load_example();
    `uvm_info(get_type_name(),
      "Nap anh vi du 3-lenh co san (cmdlink_image) vao cmdlink_mem", UVM_LOW)
  endfunction

  // APB cmd0 link toi CMD0 cua anh vi du (cmdlink_start_linkaddr()).
  // cmd_addr(0) = CMDLINK_BASE = CMD0_ADDR, nen cfg_apb_cmd0 mac dinh da tro dung;
  // override de dung ro helper cua package.
  virtual task cfg_apb_cmd0();
    super.cfg_apb_cmd0();
    apb_write(ch_addr(ch,O_LINKADDR), cmdlink_start_linkaddr());
  endtask

endclass : dma350_vseq_cmdlink_apb_example

`endif // DMA350_VSEQ_CMDLINK_APB_EXAMPLE_SV
