//==============================================================================
// dma350_apb_read_seq.sv
//------------------------------------------------------------------------------
// Doc 1 thanh ghi 32-bit qua apb_agent_master; ket qua trong 'data' sau khi
// start() xong. apb_driver_master ghi nguoc prdata/pslverr vao CHINH item (cung
// handle) truoc item_done -> sau finish_item, req.prdata la du lieu doc duoc.
//==============================================================================
`ifndef DMA350_APB_READ_SEQ_SV
`define DMA350_APB_READ_SEQ_SV

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

`endif // DMA350_APB_READ_SEQ_SV
