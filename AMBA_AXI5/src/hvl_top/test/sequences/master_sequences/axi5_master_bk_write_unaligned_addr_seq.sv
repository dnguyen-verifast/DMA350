`ifndef AXI5_MASTER_BK_WRITE_UNALIGNED_ADDR_SEQ_INCLUDED_
`define AXI5_MASTER_BK_WRITE_UNALIGNED_ADDR_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_master_bk_write_unaligned_addr_seq
// Extends the axi5_master_base_seq and randomises the req item
//--------------------------------------------------------------------------------------------
class axi5_master_bk_write_unaligned_addr_seq extends axi5_master_bk_base_seq;
  `uvm_object_utils(axi5_master_bk_write_unaligned_addr_seq)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_master_bk_write_unaligned_addr_seq");
  extern task body();
endclass : axi5_master_bk_write_unaligned_addr_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi5_master_bk_write_unaligned_addr_seq
//--------------------------------------------------------------------------------------------
function axi5_master_bk_write_unaligned_addr_seq::new(string name = "axi5_master_bk_write_unaligned_addr_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates the req of type master transaction and randomises the req
//--------------------------------------------------------------------------------------------
task axi5_master_bk_write_unaligned_addr_seq::body();
  super.body();

  start_item(req);
  if(!req.randomize() with {req.awaddr % 4 !=0;
                              req.awsize == WRITE_2_BYTES;
                              req.tx_type == WRITE;
                              req.awburst == WRITE_FIXED;
                              req.transfer_type == BLOCKING_WRITE;}) begin
    `uvm_fatal("axi5","Rand failed");
  end
  finish_item(req);
  
  `uvm_info(get_type_name(), $sformatf("DEBUG_MSHA :: master_seq \n%s",req.sprint()), UVM_NONE); 

endtask : body

`endif

