`ifndef AXI5_MASTER_NBK_READ_8B_TRANSFER_SEQ_INCLUDED_
`define AXI5_MASTER_NBK_READ_8B_TRANSFER_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_master_nbk_read_8b_transfer_seq
// Extends the axi5_master_nbk_base_seq and randomises the req item
//--------------------------------------------------------------------------------------------
class axi5_master_nbk_read_8b_transfer_seq extends axi5_master_nbk_base_seq;
  `uvm_object_utils(axi5_master_nbk_read_8b_transfer_seq)
    queue_info_ctrl_s queue_info_ctrl_r;
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_master_nbk_read_8b_transfer_seq");
  extern task body();
endclass : axi5_master_nbk_read_8b_transfer_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi5_master_nbk_read_8b_transfer_seq
//--------------------------------------------------------------------------------------------
function axi5_master_nbk_read_8b_transfer_seq::new(string name = "axi5_master_nbk_read_8b_transfer_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates the req of type master_nbk transaction and randomises the req
//--------------------------------------------------------------------------------------------
task axi5_master_nbk_read_8b_transfer_seq::body();
  super.body();
  start_item(req);
  if(!req.randomize() with {req.arsize == READ_1_BYTE;
                            req.araddr == queue_info_ctrl_r.addr;
                            req.arid == queue_info_ctrl_r.id;
                            req.tx_type == READ;
                            req.arburst == READ_WRAP;
                            req.transfer_type == NON_BLOCKING_READ;}) begin

    `uvm_fatal("axi5","Rand failed");
  end
  req.print();
  finish_item(req);

endtask : body

`endif

