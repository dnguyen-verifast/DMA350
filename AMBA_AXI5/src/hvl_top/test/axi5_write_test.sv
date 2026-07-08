`ifndef AXI5_WRITE_TEST_INCLUDED_
`define AXI5_WRITE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_write_test
// Extends the base test and starts the virtual sequenceof write
//--------------------------------------------------------------------------------------------
class axi5_write_test extends axi5_base_test;
  `uvm_component_utils(axi5_write_test)

  //Variable : axi5_virtual_write_seq_h
  //Instatiation of axi5_virtual_write_seq
  axi5_virtual_write_seq  axi5_virtual_write_seq_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_write_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi5_write_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi5_write_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi5_write_test::new(string name = "axi5_write_test",
                                 uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates the axi5_virtual_write_seq sequence and starts the write virtual sequences
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi5_write_test::run_phase(uvm_phase phase);
	super.run_phase(phase);
  axi5_virtual_write_seq_h=axi5_virtual_write_seq::type_id::create("axi5_virtual_write_seq_h");
  `uvm_info(get_type_name(),$sformatf("axi5_write_test"),UVM_LOW);
	phase.get_objection().set_drain_time(this, 3000ns);
  phase.raise_objection(this);
  axi5_virtual_write_seq_h.start(axi5_env_h.axi5_virtual_seqr_h);
  `uvm_info(get_type_name(),$sformatf("out_axi5_write_test"),UVM_LOW);
  phase.drop_objection(this);

endtask : run_phase

`endif

