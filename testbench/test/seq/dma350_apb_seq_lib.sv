//==============================================================================
// dma350_apb_seq_lib.sv
//------------------------------------------------------------------------------
// Sequence APB directed cho viec cau hinh DMA-350 qua apb_agent_master.
//
// LUU Y QUAN TRONG: apb_seq_item_master co constraint c_data{pwdata>16} va
// c_addr{paddr[1:0]==0}. Ghi directed (vd ENABLECMD=1) se VI PHAM c_data neu
// randomize() -> cac sequence nay GAN FIELD TRUC TIEP, KHONG randomize.
//
// apb_driver_master ghi nguoc prdata/pslverr vao CHINH item (cung handle) truoc
// item_done -> sau finish_item, req.prdata la du lieu doc duoc.
//==============================================================================
`ifndef DMA350_APB_SEQ_LIB_SV
`define DMA350_APB_SEQ_LIB_SV

//------------------------------------------------------------------------------
// Ghi 1 thanh ghi 32-bit (word-aligned). pprot mac dinh 3'b001 = privileged
// (khop pprot RTL dung de cap quyen truy cap channel frame).
//------------------------------------------------------------------------------
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

//------------------------------------------------------------------------------
// Doc 1 thanh ghi 32-bit; ket qua trong 'data' sau khi start() xong.
//------------------------------------------------------------------------------
class dma350_apb_read_seq extends uvm_sequence #(apb_seq_item_master);
  `uvm_object_utils(dma350_apb_read_seq)

  bit [31:0] addr;
  bit [31:0] data;      // out: prdata
  bit        slverr;    // out
  bit [2:0]  prot = 3'b001;

  function new(string name = "dma350_apb_read_seq");
    super.new(name);
  endfunction

  virtual task body();
    req = apb_seq_item_master#()::type_id::create("req");
    start_item(req);
    req.paddr   = addr;
    req.pwrite  = 1'b0;
    req.pwdata  = '0;
    req.pstrb   = '0;
    req.pprot   = prot;
    req.pwakeup = 1'b1;
    req.pdebug  = 1'b0;
    finish_item(req);
    // driver da copy prdata/pslverr vao req (cung handle) truoc item_done
    data   = req.prdata;
    slverr = req.pslverr;
  endtask
endclass

`endif // DMA350_APB_SEQ_LIB_SV
