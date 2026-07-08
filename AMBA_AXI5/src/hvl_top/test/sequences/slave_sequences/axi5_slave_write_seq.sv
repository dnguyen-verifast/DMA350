`ifndef AXI5_SLAVE_WRITE_SEQ_INCLUDED_
`define AXI5_SLAVE_WRITE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_slave_write_seq
// Extends the axi5_slave_base_seq and randomises the req item
//--------------------------------------------------------------------------------------------
class axi5_slave_write_seq extends axi5_slave_base_seq;
  `uvm_object_utils(axi5_slave_write_seq)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_slave_write_seq");
  extern task body();
endclass : axi5_slave_write_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi5_slave_write_seq
//  intializes new memory for the object
//--------------------------------------------------------------------------------------------
function axi5_slave_write_seq::new(string name = "axi5_slave_write_seq");
  super.new(name);
endfunction : new

//-------------------------------------------------------
//Task : Body
//Creates the req of type slave transaction and randomises the req.
//-------------------------------------------------------
task axi5_slave_write_seq::body();
  req=axi5_slave_tx::type_id::create("req");

  start_item(req);
  if(!req.randomize() with {req.bresp == WRITE_OKAY;}) begin
    `uvm_error(get_type_name(),"randomization failed");
  end
  req.print();
  finish_item(req);
endtask :body

`endif

