`ifndef AXI5_ENV_INCLUDED_
`define AXI5_ENV_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5 env
// Description:
// Environment contains slave_agent_top,master_agent_top and axi5_virtual_sequencer
//--------------------------------------------------------------------------------------------
class axi5_env extends uvm_env;
  `uvm_component_utils(axi5_env)
  
  //Variable : axi5_env_cfg_h
  //Declaring handle for axi5_env_config_object
  axi5_env_config axi5_env_cfg_h;

  //Variable : axi5_master_agent_h
  //Declaring axi5 master agent handle 
  axi5_master_agent axi5_master_agent_h[];
 
  //Variable : axi5_slave_agent_h
  //Declaring axi5 slave agent handle
  axi5_slave_agent axi5_slave_agent_h[];

  //Variable : axi5_virtual_seqr_h
  //Declaring axi5_virtual seqr handle
  axi5_virtual_sequencer axi5_virtual_seqr_h;

  //Variable : axi5__scoreboard_h
  //Declaring axi5 scoreboard handle
  axi5_scoreboard axi5_scoreboard_h;
  
  // Variable: axi5_master_agent_cfg_h;
  // Handle for axi5_master agent configuration
  axi5_master_agent_config axi5_master_agent_cfg_h[];

  // Variable: axi5_slave_agent_cfg_h;        
  // Handle for axi5_slave agent configuration
  axi5_slave_agent_config axi5_slave_agent_cfg_h[];

 
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_env", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);

endclass : axi5_env

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
// name - axi5_env
// parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi5_env::new(string name = "axi5_env",uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Description:
// Create required components
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_env::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  if(!uvm_config_db #(axi5_env_config)::get(this,"","axi5_env_config",axi5_env_cfg_h)) begin
    `uvm_fatal("FATAL_ENV_AGENT_CONFIG", $sformatf("Couldn't get the env_agent_config from config_db"))
  end
  
  axi5_master_agent_cfg_h = new[axi5_env_cfg_h.no_of_masters];
  foreach(axi5_master_agent_cfg_h[i]) begin
    if(!uvm_config_db#(axi5_master_agent_config)::get(this,"",$sformatf("axi5_master_agent_config[%0d]",i),axi5_master_agent_cfg_h[i])) begin
      `uvm_fatal("FATAL_MA_AGENT_CONFIG", $sformatf("Couldn't get the axi5_master_agent_config[%0d] from config_db",i))
    end
  end

  axi5_slave_agent_cfg_h = new[axi5_env_cfg_h.no_of_slaves];
  foreach(axi5_slave_agent_cfg_h[i]) begin
    if(!uvm_config_db #(axi5_slave_agent_config)::get(this,"",$sformatf("axi5_slave_agent_config[%0d]",i),axi5_slave_agent_cfg_h[i])) begin
      `uvm_fatal("FATAL_SA_AGENT_CONFIG", $sformatf("Couldn't get the axi5_slave_agent_config[%0d] from config_db",i))
    end
//		`uvm_config_db #(axi5_slave_agent_config)::set(this,$sformatf("axi5_slave_agent_h[%0d]",i),"axi5_slave_agent_cfg", axi5_slave_agent_cfg_h[i]); // !!!!
  end

  axi5_master_agent_h = new[axi5_env_cfg_h.no_of_masters];
  foreach(axi5_master_agent_h[i]) begin
    axi5_master_agent_h[i]=axi5_master_agent::type_id::create($sformatf("axi5_master_agent_h[%0d]",i),this);
  end

  axi5_slave_agent_h = new[axi5_env_cfg_h.no_of_slaves];
  foreach(axi5_slave_agent_h[i]) begin
    axi5_slave_agent_h[i]=axi5_slave_agent::type_id::create($sformatf("axi5_slave_agent_h[%0d]",i),this);
  end
  
  if(axi5_env_cfg_h.has_virtual_seqr) begin
    axi5_virtual_seqr_h = axi5_virtual_sequencer::type_id::create("axi5_virtual_seqr_h",this);
  end

  if(axi5_env_cfg_h.has_scoreboard) begin
    axi5_scoreboard_h=axi5_scoreboard::type_id::create("axi5_scoreboard_h",this);
  end
  
  foreach(axi5_master_agent_h[i]) begin
    axi5_master_agent_h[i].axi5_master_agent_cfg_h = axi5_master_agent_cfg_h[i];
  end
  
  foreach(axi5_slave_agent_h[i]) begin
    axi5_slave_agent_h[i].axi5_slave_agent_cfg_h = axi5_slave_agent_cfg_h[i];
  end
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: connect_phase
// Description:
// To connect driver and sequencer
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  if(axi5_env_cfg_h.has_virtual_seqr) begin
    foreach(axi5_master_agent_h[i]) begin
      axi5_virtual_seqr_h.axi5_master_write_seqr_h = axi5_master_agent_h[i].axi5_master_write_seqr_h;
      axi5_virtual_seqr_h.axi5_master_read_seqr_h = axi5_master_agent_h[i].axi5_master_read_seqr_h;
    end
    foreach(axi5_slave_agent_h[i]) begin
      axi5_virtual_seqr_h.axi5_slave_write_seqr_h = axi5_slave_agent_h[i].axi5_slave_write_seqr_h;
      axi5_virtual_seqr_h.axi5_slave_read_seqr_h = axi5_slave_agent_h[i].axi5_slave_read_seqr_h;
    end
  end
  if(axi5_env_cfg_h.has_scoreboard) begin
    foreach(axi5_master_agent_h[i]) begin
      axi5_master_agent_h[i].axi5_master_mon_proxy_h.axi5_master_read_address_analysis_port.connect(axi5_scoreboard_h.axi5_master_read_address_analysis_fifo.analysis_export);
      axi5_master_agent_h[i].axi5_master_mon_proxy_h.axi5_master_read_data_analysis_port.connect(axi5_scoreboard_h.axi5_master_read_data_analysis_fifo.analysis_export);
      axi5_master_agent_h[i].axi5_master_mon_proxy_h.axi5_master_write_address_analysis_port.connect(axi5_scoreboard_h.axi5_master_write_address_analysis_fifo.analysis_export);
      axi5_master_agent_h[i].axi5_master_mon_proxy_h.axi5_master_write_data_analysis_port.connect(axi5_scoreboard_h.axi5_master_write_data_analysis_fifo.analysis_export);
      axi5_master_agent_h[i].axi5_master_mon_proxy_h.axi5_master_write_response_analysis_port.connect(axi5_scoreboard_h.axi5_master_write_response_analysis_fifo.analysis_export);
    end

    foreach(axi5_slave_agent_h[i]) begin
      axi5_slave_agent_h[i].axi5_slave_mon_proxy_h.axi5_slave_write_address_analysis_port.connect(axi5_scoreboard_h.axi5_slave_write_address_analysis_fifo.analysis_export);
      axi5_slave_agent_h[i].axi5_slave_mon_proxy_h.axi5_slave_write_data_analysis_port.connect(axi5_scoreboard_h.axi5_slave_write_data_analysis_fifo.analysis_export);
      axi5_slave_agent_h[i].axi5_slave_mon_proxy_h.axi5_slave_write_response_analysis_port.connect(axi5_scoreboard_h.axi5_slave_write_response_analysis_fifo.analysis_export);
      axi5_slave_agent_h[i].axi5_slave_mon_proxy_h.axi5_slave_read_address_analysis_port.connect(axi5_scoreboard_h.axi5_slave_read_address_analysis_fifo.analysis_export);
      axi5_slave_agent_h[i].axi5_slave_mon_proxy_h.axi5_slave_read_data_analysis_port.connect(axi5_scoreboard_h.axi5_slave_read_data_analysis_fifo.analysis_export);
    end 
  end
endfunction : connect_phase

`endif

