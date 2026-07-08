`ifndef AXI5_SLAVE_TX_INCLUDED_
`define AXI5_SLAVE_TX_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_slave_tx
//  This class holds the data items required to drive stimulus to dut
//  and also holds methods that manipulate those data items
//--------------------------------------------------------------------------------------------
class axi5_slave_tx extends axi5_base_tx;
  
  `uvm_object_utils(axi5_slave_tx)
  //-------------------------------------------------------
  // Constraints
  //-------------------------------------------------------
  
  //Constraint : rdata_c1
  //Adding constraint to restrict the read data based on awlength
  constraint rdata_c1 { rdata.size() == arlen + 1; 
                        rdata.size() != 0;}
  
  //Constraint : rresp_c1
  //Adding constraint to select the type of read response
  constraint rresp_c1 {soft rresp == READ_OKAY;}

  //Constraint : rresp_c1
  //Adding constraint to select the type of read response
  constraint bresp_c1 {soft bresp == WRITE_OKAY;}

  //Constraint : wait_states_c1             
  //To randomise the wait states in range of 0 to 3
  constraint wait_states_c1 {soft no_of_wait_states inside {[0:3]};}
                    
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_slave_tx");
endclass : axi5_slave_tx

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the class object
//
// Parameters:
// name - axi5_slave_tx
//--------------------------------------------------------------------------------------------
function axi5_slave_tx::new(string name = "axi5_slave_tx");
  super.new(name);
endfunction : new

`endif

