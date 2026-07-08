`ifndef AXI5_SLAVE_AGENT_INCLUDED_
`define AXI5_SLAVE_AGENT_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_slave_agent
// This agent has sequencer, driver_proxy, monitor_proxy for axi5  
//--------------------------------------------------------------------------------------------
class axi5_slave_agent extends uvm_agent;
  `uvm_component_utils(axi5_slave_agent)

  // Variable: axi5_slave_agent_cfg_h;
  // Handle for axi5_slave agent configuration
  axi5_slave_agent_config axi5_slave_agent_cfg_h;

  // Varible: axi5_slave_write_seqr_h 
  // Handle for slave write sequencer
  axi5_slave_write_sequencer axi5_slave_write_seqr_h;
  
  // Varible: axi5_slave_read_seqr_h 
  // Handle for slave read sequencer
  axi5_slave_read_sequencer axi5_slave_read_seqr_h;

  // Variable: axi5_slave_drv_proxy_h
  // Handle for axi5_slave driver proxy
  axi5_slave_driver_proxy axi5_slave_drv_proxy_h;

  // Variable: axi5_slave_mon_proxy_h
  // Handle for axi5_slave monitor proxy
  axi5_slave_monitor_proxy axi5_slave_mon_proxy_h;

  // Variable: axi5_slave_coverage
  // Decalring a handle for axi5_slave_coverage
  axi5_slave_coverage axi5_slave_cov_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_slave_agent", uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);

endclass : axi5_slave_agent

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the axi5_slave_agent class object
//
// Parameters:
//  name - instance name of the  axi5_slave_agent
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi5_slave_agent::new(string name = "axi5_slave_agent", uvm_component parent);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Creates the required ports, gets the required configuration from config_db
//
// Parameters:
//  phase - stores the current phase
//--------------------------------------------------------------------------------------------
function void axi5_slave_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);
//  axi5_slave_agent_cfg_h = axi5_slave_agent_config::type_id::create("axi5_slave_agent_cfg_h",this); //!!!!
//  axi5_slave_agent_cfg_h = new(); //!!!!
	if(axi5_slave_agent_cfg_h == null) begin
		`uvm_fatal(get_type_name(),"Could not get config agent slave from enn")
	end
	`uvm_info("SLAVE_AGENT",$sformatf("read_data_mode = %0b",axi5_slave_agent_cfg_h.read_data_mode),UVM_LOW);	
			
   if(axi5_slave_agent_cfg_h.is_active == UVM_ACTIVE) begin
     axi5_slave_drv_proxy_h  = axi5_slave_driver_proxy::type_id::create("axi5_slave_drv_proxy_h",this);
     axi5_slave_write_seqr_h = axi5_slave_write_sequencer::type_id::create("axi5_slave_write_seqr_h",this);
     axi5_slave_read_seqr_h  = axi5_slave_read_sequencer::type_id::create("axi5_slave_read_seqr_h",this);
   end

   axi5_slave_mon_proxy_h = axi5_slave_monitor_proxy::type_id::create("axi5_slave_mon_proxy_h",this);

   if(axi5_slave_agent_cfg_h.has_coverage) begin
    axi5_slave_cov_h = axi5_slave_coverage::type_id::create("axi5_slave_cov_h",this);
   end
endfunction : build_phase

//--------------------------------------------------------------------------------------------
//  Function: connect_phase 
//  Connecting axi5 slave driver, slave monitor and slave sequencer for configuration
//
//  Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_slave_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  
  if(axi5_slave_agent_cfg_h.is_active == UVM_ACTIVE) begin
    axi5_slave_drv_proxy_h.axi5_slave_agent_cfg_h  = axi5_slave_agent_cfg_h;
    axi5_slave_write_seqr_h.axi5_slave_agent_cfg_h = axi5_slave_agent_cfg_h;
    axi5_slave_read_seqr_h.axi5_slave_agent_cfg_h  = axi5_slave_agent_cfg_h;
    axi5_slave_cov_h.axi5_slave_agent_cfg_h        = axi5_slave_agent_cfg_h;
    
    // Connecting the ports
    axi5_slave_drv_proxy_h.axi_write_seq_item_port.connect(axi5_slave_write_seqr_h.seq_item_export);
    axi5_slave_drv_proxy_h.axi_read_seq_item_port.connect(axi5_slave_read_seqr_h.seq_item_export);
  end

  if(axi5_slave_agent_cfg_h.has_coverage) begin
    axi5_slave_cov_h.axi5_slave_agent_cfg_h = axi5_slave_agent_cfg_h; 
    // Connecting monitor_proxy port to coverage export
    axi5_slave_mon_proxy_h.axi5_slave_read_address_analysis_port.connect(axi5_slave_cov_h.analysis_export);
    axi5_slave_mon_proxy_h.axi5_slave_read_data_analysis_port.connect(axi5_slave_cov_h.analysis_export);
    axi5_slave_mon_proxy_h.axi5_slave_write_address_analysis_port.connect(axi5_slave_cov_h.analysis_export);
    axi5_slave_mon_proxy_h.axi5_slave_write_data_analysis_port.connect(axi5_slave_cov_h.analysis_export);
    axi5_slave_mon_proxy_h.axi5_slave_write_response_analysis_port.connect(axi5_slave_cov_h.analysis_export);
  end

  axi5_slave_mon_proxy_h.axi5_slave_agent_cfg_h = axi5_slave_agent_cfg_h;

endfunction: connect_phase

`endif

