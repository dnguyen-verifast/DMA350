`ifndef AXI5_MASTER_NBK_WRITE_UNALIGNED_ADDR_SEQ_INCLUDED_
`define AXI5_MASTER_NBK_WRITE_UNALIGNED_ADDR_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_master_nbk_write_unaligned_addr_seq
// Extends the axi5_master_base_seq and randomises the req item
//--------------------------------------------------------------------------------------------
class axi5_master_nbk_write_unaligned_addr_seq extends axi5_master_nbk_base_seq;
  `uvm_object_utils(axi5_master_nbk_write_unaligned_addr_seq)

	int len_min, len_max;
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_master_nbk_write_unaligned_addr_seq");
  extern task body();
endclass : axi5_master_nbk_write_unaligned_addr_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi5_master_nbk_write_unaligned_addr_seq
//--------------------------------------------------------------------------------------------
function axi5_master_nbk_write_unaligned_addr_seq::new(string name = "axi5_master_nbk_write_unaligned_addr_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates the req of type master transaction and randomises the req
//--------------------------------------------------------------------------------------------
task axi5_master_nbk_write_unaligned_addr_seq::body();
  super.body();
 
  start_item(req);
  if(!req.randomize() with {
                             req.awsize == WRITE_2_BYTES;
                             req.awaddr <= 32'hfff;
                             req.awaddr%2 != 0; // !!!! fix awaddr==req.awaddr % (2**req.awsize) != 0; to below 
                             req.awburst == WRITE_FIXED;
                             req.awlen == 5; //!!!! [2:0] awlen so that should be set awlen <= 7
                             req.tx_type == WRITE;
                             req.transfer_type == NON_BLOCKING_WRITE;
                           }) begin
    `uvm_fatal("axi5","Rand failed");
  end
  
  `uvm_info(get_type_name(), $sformatf("master_seq \n%s",req.sprint()), UVM_NONE); 
  finish_item(req);

endtask : body

`endif

