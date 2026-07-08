`ifndef AXI5_MASTER_NBK_WRITE_8B_TRANSFER_SEQ_INCLUDED_
`define AXI5_MASTER_NBK_WRITE_8B_TRANSFER_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_master_nbk_write_8b_transfer_seq
// Extends the axi5_master_base_seq and randomises the req item
//--------------------------------------------------------------------------------------------
class axi5_master_nbk_write_8b_transfer_seq extends axi5_master_nbk_base_seq;
  `uvm_object_utils(axi5_master_nbk_write_8b_transfer_seq)
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_master_nbk_write_8b_transfer_seq");
  extern task body();
endclass : axi5_master_nbk_write_8b_transfer_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi5_master_nbk_write_8b_transfer_seq
//--------------------------------------------------------------------------------------------
function axi5_master_nbk_write_8b_transfer_seq::new(string name = "axi5_master_nbk_write_8b_transfer_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates the req of type master transaction and randomises the req
//--------------------------------------------------------------------------------------------
task axi5_master_nbk_write_8b_transfer_seq::body();
  super.body();
  start_item(req);
  if(!req.randomize() with {req.awsize == WRITE_1_BYTE;
                              req.awaddr <= 32'hfff;
                              req.tx_type == WRITE;
                              req.awburst == WRITE_WRAP;
                              req.transfer_type == NON_BLOCKING_WRITE;}) begin
    `uvm_fatal("axi5","Rand failed");
  end
  
  `uvm_info(get_type_name(), $sformatf("DEBUG_MSHA :: master_seq \n%s",req.sprint()), UVM_NONE); 
  finish_item(req);

endtask : body

`endif

