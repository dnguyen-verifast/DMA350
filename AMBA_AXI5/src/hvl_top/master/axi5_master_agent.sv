`ifndef AXI5_MASTER_AGENT_INCLUDED_
`define AXI5_MASTER_AGENT_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_master_agent
// This agent is a configurable with respect to configuration which can create active and passive components
// It contains testbench components like sequencer,driver_proxy and monitor_proxy for AXI5
//--------------------------------------------------------------------------------------------
class axi5_master_agent extends uvm_agent;
  `uvm_component_utils(axi5_master_agent)

  // Variable: axi5_master_agent_cfg_h
  // Declaring handle for master agent configuration class 
  axi5_master_agent_config axi5_master_agent_cfg_h;

  // Varible: axi5_master_write_seqr_h 
  // Handle for master write sequencer
  axi5_master_write_sequencer axi5_master_write_seqr_h;
  
  // Varible: axi5_master_read_seqr_h 
  // Handle for master read sequencer
  axi5_master_read_sequencer axi5_master_read_seqr_h;
  
  // Variable: axi5_master_drv_proxy_h
  // Creating a Handle for axi5_master driver proxy 
  axi5_master_driver_proxy axi5_master_drv_proxy_h;

  // Variable: axi5_master_mon_proxy_h
  // Declaring a handle for axi5_master monitor proxy 
  axi5_master_monitor_proxy axi5_master_mon_proxy_h;
  
  // Variable: axi5_master_coverage
  // Decalring a handle for axi5_master_coverage
  axi5_master_coverage axi5_master_cov_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_master_agent", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);

endclass : axi5_master_agent

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi5_master_agent
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi5_master_agent::new(string name = "axi5_master_agent", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
//  Function: build_phase
//  Creates the required ports, gets the required configuration from config_db
//
//  Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_master_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  if(axi5_master_agent_cfg_h.is_active == UVM_ACTIVE) begin
    axi5_master_drv_proxy_h=axi5_master_driver_proxy::type_id::create("axi5_master_drv_proxy_h",this);
    axi5_master_write_seqr_h=axi5_master_write_sequencer::type_id::create("axi5_master_write_seqr_h",this);
    axi5_master_read_seqr_h=axi5_master_read_sequencer::type_id::create("axi5_master_read_seqr_h",this);
  end
  
  axi5_master_mon_proxy_h=axi5_master_monitor_proxy::type_id::create("axi5_master_mon_proxy_h",this);
  
  if(axi5_master_agent_cfg_h.has_coverage) begin
   axi5_master_cov_h = axi5_master_coverage ::type_id::create("axi5_master_cov_h",this);
  end

endfunction : build_phase

//--------------------------------------------------------------------------------------------
//  Function: connect_phase 
//  Connecting axi5 master driver, master monitor and master sequencer for configuration
//
//  Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_master_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if(axi5_master_agent_cfg_h.is_active == UVM_ACTIVE) begin
    axi5_master_drv_proxy_h.axi5_master_agent_cfg_h = axi5_master_agent_cfg_h;
    axi5_master_write_seqr_h.axi5_master_agent_cfg_h = axi5_master_agent_cfg_h;
    axi5_master_read_seqr_h.axi5_master_agent_cfg_h = axi5_master_agent_cfg_h;
    axi5_master_cov_h.axi5_master_agent_cfg_h = axi5_master_agent_cfg_h;
  
    //Connecting the ports
    axi5_master_drv_proxy_h.axi_write_seq_item_port.connect(axi5_master_write_seqr_h.seq_item_export);
    axi5_master_drv_proxy_h.axi_read_seq_item_port.connect(axi5_master_read_seqr_h.seq_item_export);
  end

  if(axi5_master_agent_cfg_h.has_coverage) begin
    axi5_master_cov_h.axi5_master_agent_cfg_h = axi5_master_agent_cfg_h;   
    //Connecting monitor_proxy port to coverage export
    axi5_master_mon_proxy_h.axi5_master_read_address_analysis_port.connect(axi5_master_cov_h.analysis_export);
    axi5_master_mon_proxy_h.axi5_master_read_data_analysis_port.connect(axi5_master_cov_h.analysis_export);
    axi5_master_mon_proxy_h.axi5_master_write_address_analysis_port.connect(axi5_master_cov_h.analysis_export);
    axi5_master_mon_proxy_h.axi5_master_write_data_analysis_port.connect(axi5_master_cov_h.analysis_export);
    axi5_master_mon_proxy_h.axi5_master_write_response_analysis_port.connect(axi5_master_cov_h.analysis_export);
  end
  
  axi5_master_mon_proxy_h.axi5_master_agent_cfg_h = axi5_master_agent_cfg_h;

endfunction : connect_phase

`endif

