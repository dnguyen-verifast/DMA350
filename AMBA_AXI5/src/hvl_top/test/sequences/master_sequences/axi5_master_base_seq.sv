`ifndef AXI5_MASTER_BASE_SEQ_INCLUDED_
`define AXI5_MASTER_BASE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_master_base_seq 
// creating axi5_master_base_seq class extends from uvm_sequence
//--------------------------------------------------------------------------------------------
class axi5_master_base_seq extends uvm_sequence #(axi5_master_tx);

  //factory registration
  `uvm_object_utils(axi5_master_base_seq)
  
  //-------------------------------------------------------
  // Externally defined Function
  //-------------------------------------------------------
  extern function new(string name = "axi5_master_base_seq");

endclass : axi5_master_base_seq

//-----------------------------------------------------------------------------
// Constructor: new
// Initializes the axi5_master_sequence class object
//
// Parameters:
//  name - instance name of the config_template
//-----------------------------------------------------------------------------
function axi5_master_base_seq::new(string name = "axi5_master_base_seq");
  super.new(name);
endfunction : new

`endif
