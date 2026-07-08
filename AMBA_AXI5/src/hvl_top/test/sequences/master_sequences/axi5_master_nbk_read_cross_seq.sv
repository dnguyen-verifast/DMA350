`ifndef AXI5_MASTER_NBK_READ_CROSS_SEQ_INCLUDED_
`define AXI5_MASTER_NBK_READ_CROSS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_master_nbk_read_cross_seq
// Extends the axi5_master_nbk_base_seq and randomises the req item
//--------------------------------------------------------------------------------------------
class axi5_master_nbk_read_cross_seq extends axi5_master_nbk_base_seq;
  `uvm_object_utils(axi5_master_nbk_read_cross_seq)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_master_nbk_read_cross_seq");
  extern task body();
endclass : axi5_master_nbk_read_cross_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi5_master_nbk_read_cross_seq
//--------------------------------------------------------------------------------------------
function axi5_master_nbk_read_cross_seq::new(string name = "axi5_master_nbk_read_cross_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates the req of type master_nbk transaction and randomises the req
//--------------------------------------------------------------------------------------------
task axi5_master_nbk_read_cross_seq::body();
  super.body(); 
begin
  start_item(req);
  if(!req.randomize() with {req.arsize == READ_4_BYTES;
                            req.arlen  == 4; 
                            req.tx_type == READ;
                            req.arburst == READ_INCR;
                            req.transfer_type == NON_BLOCKING_READ;}) begin

    `uvm_fatal("axi5","Rand failed");
  end
  req.print();
  finish_item(req);


  start_item(req);
  if(!req.randomize() with {req.arsize == READ_2_BYTES;
                            req.arlen  == 7;  //!!!! must not set arlen > 7 because i use [2:0] arlen
                            req.tx_type == READ;
                            req.arburst == READ_FIXED;
                            req.transfer_type == NON_BLOCKING_READ;}) begin

    `uvm_fatal("axi5","Rand failed");
  end
  req.print();
  finish_item(req);

end
endtask : body

`endif

