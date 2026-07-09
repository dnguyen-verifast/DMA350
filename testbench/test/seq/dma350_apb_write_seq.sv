//==============================================================================
// dma350_apb_write_seq.sv
//------------------------------------------------------------------------------
// Ghi 1 thanh ghi 32-bit (word-aligned) qua apb_agent_master. pprot mac dinh
// 3'b001 = privileged (khop pprot RTL dung de cap quyen truy cap channel frame).
//
// LUU Y: apb_seq_item_master co constraint c_data{pwdata>16} -> ghi directed
// (vd ENABLECMD=1) se VI PHAM neu randomize(). Vi vay GAN FIELD TRUC TIEP.
//==============================================================================
`ifndef DMA350_APB_WRITE_SEQ_SV
`define DMA350_APB_WRITE_SEQ_SV

class dma350_apb_write_seq extends uvm_sequence #(apb_seq_item_master);
  `uvm_object_utils(dma350_apb_write_seq)

  bit [31:0] addr;
  bit [31:0] data;
  bit [2:0]  prot = 3'b001;

  function new(string name = "dma350_apb_write_seq");
    super.new(name);
  endfunction

  virtual task body();
    req = apb_seq_item_master#()::type_id::create("req");
    start_item(req);
    // gan truc tiep - KHONG randomize (constraint pwdata>16 se chan gia tri nho)
    req.paddr   = addr;
    req.pwrite  = 1'b1;
    req.pwdata  = data;
    req.pstrb   = '1;
    req.pprot   = prot;
    req.pwakeup = 1'b1;
    req.pdebug  = 1'b0;
    finish_item(req);
    if (req.pslverr)
      `uvm_warning(get_type_name(),
        $sformatf("APB WRITE 0x%04h = 0x%08h -> PSLVERR", addr, data))
  endtask
endclass

`endif // DMA350_APB_WRITE_SEQ_SV
