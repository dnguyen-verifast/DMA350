`ifndef AXI5_MASTER_NBK_WRITE_CROSS_SEQ_INCLUDED_
`define AXI5_MASTER_NBK_WRITE_CROSS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_master_nbk_write_cross_seq
// Extends the axi5_master_base_seq and randomises the req item
//--------------------------------------------------------------------------------------------
class axi5_master_nbk_write_cross_seq extends axi5_master_nbk_base_seq;
  `uvm_object_utils(axi5_master_nbk_write_cross_seq)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_master_nbk_write_cross_seq");
  extern task body();
endclass : axi5_master_nbk_write_cross_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi5_master_nbk_write_cross_seq
//--------------------------------------------------------------------------------------------
function axi5_master_nbk_write_cross_seq::new(string name = "axi5_master_nbk_write_cross_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates the req of type master transaction and randomises the req
//--------------------------------------------------------------------------------------------
task axi5_master_nbk_write_cross_seq::body();
  super.body();
  begin

  start_item(req);
  if(!req.randomize() with {  req.awsize == WRITE_2_BYTES;
                              req.awlen == 7; //!!!! must not set awlen > 7
                              req.tx_type == WRITE;
                              req.awburst == WRITE_FIXED;
                              req.transfer_type == NON_BLOCKING_WRITE;}) begin
    `uvm_fatal("axi5","Rand failed");
  end
  
  `uvm_info(get_type_name(), $sformatf("master_seq \n%s",req.sprint()), UVM_NONE); 
  finish_item(req);


  start_item(req);
  if(!req.randomize() with {  req.awsize == WRITE_4_BYTES;
                              req.awlen == 7; //!!!! must not set awlen > 7
                              req.tx_type == WRITE;
                              req.awburst == WRITE_INCR;
                              req.transfer_type == NON_BLOCKING_WRITE;}) begin
    `uvm_fatal("axi5","Rand failed");
  end
  
  `uvm_info(get_type_name(), $sformatf("master_seq \n%s",req.sprint()), UVM_NONE); 
  finish_item(req);

  start_item(req);
  if(!req.randomize() with {  req.awsize == WRITE_2_BYTES;
                              req.awlen == 7; //!!!! must not set awlen > 7
                              req.tx_type == WRITE;
                              req.awburst == WRITE_WRAP;
                              req.transfer_type == NON_BLOCKING_WRITE;}) begin
    `uvm_fatal("axi5","Rand failed");
  end
  
  `uvm_info(get_type_name(), $sformatf("master_seq \n%s",req.sprint()), UVM_NONE); 
  finish_item(req);
end

  `uvm_info(get_type_name(), $sformatf("AFTER axi5_master_nbk_write_cross_seq"), UVM_NONE); 

endtask : body

`endif

