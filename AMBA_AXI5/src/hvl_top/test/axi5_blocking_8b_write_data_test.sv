`ifndef AXI5_BLOCKING_8B_WRITE_DATA_TEST_INCLUDED_
`define AXI5_BLOCKING_8B_WRITE_DATA_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_blocking_8b_write_data_test
// Extends the base test and starts the virtual sequenceof write
//--------------------------------------------------------------------------------------------
class axi5_blocking_8b_write_data_test extends axi5_base_test;
  `uvm_component_utils(axi5_blocking_8b_write_data_test)

  //Variable : axi5_virtual_write_seq_h
  //Instatiation of axi5_virtual_write_seq
  axi5_virtual_bk_8b_write_data_seq axi5_virtual_bk_8b_write_data_seq_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_blocking_8b_write_data_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi5_blocking_8b_write_data_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi5_blocking_8b_write_data_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi5_blocking_8b_write_data_test::new(string name = "axi5_blocking_8b_write_data_test",
                                 uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates the axi5_virtual_8b_write_data_seq sequence and starts the write virtual sequences
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi5_blocking_8b_write_data_test::run_phase(uvm_phase phase);

  axi5_virtual_bk_8b_write_data_seq_h=axi5_virtual_bk_8b_write_data_seq::type_id::create("axi5_virtual_bk_8b_write_data_seq_h");
  `uvm_info(get_type_name(),$sformatf("axi5_blocking_8b_write_data_test"),UVM_LOW);
  phase.raise_objection(this);
  axi5_virtual_bk_8b_write_data_seq_h.start(axi5_env_h.axi5_virtual_seqr_h);
  phase.drop_objection(this);

endtask : run_phase

`endif

