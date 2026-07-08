`ifndef AXI5_NON_BLOCKING_WRITE_READ_TEST_INCLUDED_
`define AXI5_NON_BLOCKING_WRITE_READ_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_non_blocking_write_read_test
// Extends the base test and starts the virtual sequenceof write
//--------------------------------------------------------------------------------------------
class axi5_non_blocking_write_read_test extends axi5_base_test;
  `uvm_component_utils(axi5_non_blocking_write_read_test)

  //Variable : axi5_virtual_nbk_write_read_seq_h
  //Instatiation of axi5_virtual_nbk_write_read_seq
  axi5_virtual_nbk_write_read_seq axi5_virtual_nbk_write_read_seq_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_non_blocking_write_read_test", uvm_component parent = null);
  extern virtual function void setup_axi5_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi5_non_blocking_write_read_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi5_non_blocking_write_read_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi5_non_blocking_write_read_test::new(string name = "axi5_non_blocking_write_read_test",
                                 uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi5_non_blocking_write_read_test::setup_axi5_slave_agent_cfg();
  super.setup_axi5_slave_agent_cfg();
  foreach(axi5_env_cfg_h.axi5_slave_agent_cfg_h[i]) begin
    axi5_env_cfg_h.axi5_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
  end
endfunction : setup_axi5_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates the axi5_virtual_write_read_seq sequence and starts the write virtual sequences
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi5_non_blocking_write_read_test::run_phase(uvm_phase phase);

  axi5_virtual_nbk_write_read_seq_h=axi5_virtual_nbk_write_read_seq::type_id::create("axi5_virtual_nbk_write_read_seq_h");
  `uvm_info(get_type_name(),$sformatf("axi5_non_blocking_write_read_test"),UVM_LOW);
  phase.raise_objection(this);
  axi5_virtual_nbk_write_read_seq_h.start(axi5_env_h.axi5_virtual_seqr_h);
  phase.drop_objection(this);

endtask : run_phase

`endif

