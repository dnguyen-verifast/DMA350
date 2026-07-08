`ifndef AXI5_MASTER_NBK_WRITE_RAND_SEQ_INCLUDED_
`define AXI5_MASTER_NBK_WRITE_RAND_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_master_nbk_write_rand_seq
// Extends the axi5_master_nbk_base_seq and randomises the req item
//--------------------------------------------------------------------------------------------
class axi5_master_nbk_write_rand_seq extends axi5_master_nbk_base_seq;
  `uvm_object_utils(axi5_master_nbk_write_rand_seq)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_master_nbk_write_rand_seq");
  extern task body();
endclass : axi5_master_nbk_write_rand_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi5_master_nbk_write_rand_seq
//--------------------------------------------------------------------------------------------
function axi5_master_nbk_write_rand_seq::new(string name = "axi5_master_nbk_write_rand_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates the req of type master_nbk transaction and randomises the req
//--------------------------------------------------------------------------------------------
task axi5_master_nbk_write_rand_seq::body();
  super.body();
  
  start_item(req);
  if(!req.randomize() with { req.tx_type == WRITE;
                             req.transfer_type == NON_BLOCKING_WRITE;
                           }) begin

    `uvm_fatal("axi5","Rand failed");
  end
  req.print();
  finish_item(req);

endtask : body

`endif

