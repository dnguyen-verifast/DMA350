`ifndef AXI5_SLAVE_BK_WRITE_32B_TRANSFER_SEQ_INCLUDED_
`define AXI5_SLAVE_BK_WRITE_32B_TRANSFER_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_slave_bk_write_32b_transfer_seq
// Extends the axi5_slave_base_seq and randomises the req item
//--------------------------------------------------------------------------------------------
class axi5_slave_bk_write_32b_transfer_seq extends axi5_slave_bk_base_seq;
  `uvm_object_utils(axi5_slave_bk_write_32b_transfer_seq)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_slave_bk_write_32b_transfer_seq");
  extern task body();
endclass : axi5_slave_bk_write_32b_transfer_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi5_slave_bk_write_32b_transfer_seq
//--------------------------------------------------------------------------------------------
function axi5_slave_bk_write_32b_transfer_seq::new(string name = "axi5_slave_bk_write_32b_transfer_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates the req of type slave transaction and randomises the req
//--------------------------------------------------------------------------------------------
task axi5_slave_bk_write_32b_transfer_seq::body();
  super.body();
  req.transfer_type=BLOCKING_WRITE;

  start_item(req);
  if(!req.randomize)begin
    `uvm_fatal("axi5","Rand failed");
  end
  
  `uvm_info(get_type_name(), $sformatf("slave_seq \n%s",req.sprint()), UVM_NONE); 
  finish_item(req);

endtask : body

`endif

