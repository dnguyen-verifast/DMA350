`ifndef AXI5_MASTER_WRITE_SEQUENCER_INCLUDED_
`define AXI5_MASTER_WRITE_SEQUENCER_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_master_write_sequencer
//--------------------------------------------------------------------------------------------
class axi5_master_write_sequencer extends uvm_sequencer#(axi5_master_tx);
  `uvm_component_utils(axi5_master_write_sequencer)

  // Variable: axi5_master_agent_cfg_h
  // Declaring handle for master agent config class 
  axi5_master_agent_config axi5_master_agent_cfg_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_master_write_sequencer", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual function void start_of_simulation_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi5_master_write_sequencer

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi5_master_write_sequencer
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi5_master_write_sequencer::new(string name = "axi5_master_write_sequencer",
                                 uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_master_write_sequencer::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: connect_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_master_write_sequencer::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase

//--------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_master_write_sequencer::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
endfunction  : end_of_elaboration_phase

//--------------------------------------------------------------------------------------------
// Function: start_of_simulation_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_master_write_sequencer::start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);
endfunction : start_of_simulation_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi5_master_write_sequencer::run_phase(uvm_phase phase);

  // Work here
  // ...

endtask : run_phase

`endif

