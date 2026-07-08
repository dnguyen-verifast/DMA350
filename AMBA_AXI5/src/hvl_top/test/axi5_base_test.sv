`ifndef AXI5_BASE_TEST_INCLUDED_
`define AXI5_BASE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_base_test
// axi5_base test has the test scenarios for testbench which has the env, config, etc.
// Sequences are created and started in the test
//--------------------------------------------------------------------------------------------
class axi5_base_test extends uvm_test;
  
  `uvm_component_utils(axi5_base_test)

  // Variable: e_cfg_h
  // Declaring environment config handle
  axi5_env_config axi5_env_cfg_h;

  // Variable: axi5_env_h
  // Handle for environment 
  axi5_env axi5_env_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_base_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void setup_axi5_env_cfg();
  extern virtual function void setup_axi5_master_agent_cfg();
  extern virtual function void setup_axi5_slave_agent_cfg();
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi5_base_test

//--------------------------------------------------------------------------------------------
// Construct: new
//  Initializes class object
//
// Parameters:
//  name - axi5_base_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi5_base_test::new(string name = "axi5_base_test",uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//  Create required ports
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_base_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  // Setup the environemnt cfg 
  setup_axi5_env_cfg();
  // Create the environment
  axi5_env_h = axi5_env::type_id::create("axi5_env_h",this);
endfunction : build_phase


//--------------------------------------------------------------------------------------------
// Function: setup_axi5_env_cfg
// Setup the environment configuration with the required values
// and store the handle into the config_db
//--------------------------------------------------------------------------------------------
function void axi5_base_test:: setup_axi5_env_cfg();
  axi5_env_cfg_h = axi5_env_config::type_id::create("axi5_env_cfg_h");
 
  axi5_env_cfg_h.has_scoreboard = 1;
  axi5_env_cfg_h.has_virtual_seqr = 1;
  axi5_env_cfg_h.no_of_masters = NO_OF_MASTERS;
  axi5_env_cfg_h.no_of_slaves = NO_OF_SLAVES;

  // Setup the axi5_master agent cfg 
  setup_axi5_master_agent_cfg();
  
  // Setup the axi5_slave agent cfg 
  setup_axi5_slave_agent_cfg();

  // set method for axi5_env_cfg
  uvm_config_db #(axi5_env_config)::set(this,"*","axi5_env_config",axi5_env_cfg_h);
  `uvm_info(get_type_name(),$sformatf("\nAXI5_ENV_CONFIG\n%s",axi5_env_cfg_h.sprint()),UVM_LOW);
endfunction: setup_axi5_env_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi5_master_agent_cfg
// Setup the axi5_master agent configuration with the required values
// and store the handle into the config_db
//--------------------------------------------------------------------------------------------
function void axi5_base_test::setup_axi5_master_agent_cfg();
  bit [63:0]local_min_address;
  bit [63:0]local_max_address;
  axi5_env_cfg_h.axi5_master_agent_cfg_h = new[axi5_env_cfg_h.no_of_masters];
  foreach(axi5_env_cfg_h.axi5_master_agent_cfg_h[i])begin
    axi5_env_cfg_h.axi5_master_agent_cfg_h[i] =
    axi5_master_agent_config::type_id::create($sformatf("axi5_master_agent_cfg_h[%0d]",i));
    axi5_env_cfg_h.axi5_master_agent_cfg_h[i].is_active   = uvm_active_passive_enum'(UVM_ACTIVE);
    axi5_env_cfg_h.axi5_master_agent_cfg_h[i].has_coverage = 1; 
    uvm_config_db#(axi5_master_agent_config)::set(this,"*env*",$sformatf("axi5_master_agent_config[%0d]",i),axi5_env_cfg_h.axi5_master_agent_cfg_h[i]);
  end

  for(int i =0; i<NO_OF_SLAVES; i++) begin
    if(i == 0) begin  
      axi5_env_cfg_h.axi5_master_agent_cfg_h[i].master_min_addr_range(i,0);
      local_min_address = axi5_env_cfg_h.axi5_master_agent_cfg_h[i].master_min_addr_range_array[i];
      axi5_env_cfg_h.axi5_master_agent_cfg_h[i].master_max_addr_range(i,2**(SLAVE_MEMORY_SIZE)-1 );
      local_max_address = axi5_env_cfg_h.axi5_master_agent_cfg_h[i].master_max_addr_range_array[i];
    end
    else begin
      axi5_env_cfg_h.axi5_master_agent_cfg_h[i].master_min_addr_range(i,local_max_address + SLAVE_MEMORY_GAP);
      local_min_address = axi5_env_cfg_h.axi5_master_agent_cfg_h[i].master_min_addr_range_array[i];
      axi5_env_cfg_h.axi5_master_agent_cfg_h[i].master_max_addr_range(i,local_max_address+ 2**(SLAVE_MEMORY_SIZE)-1 + 
                                                                      SLAVE_MEMORY_GAP);
      local_max_address = axi5_env_cfg_h.axi5_master_agent_cfg_h[i].master_max_addr_range_array[i];
    end
   `uvm_info(get_type_name(),$sformatf("\nAXI5_MASTER_CONFIG[%0d]\n%s",i,axi5_env_cfg_h.axi5_master_agent_cfg_h[i].sprint()),UVM_LOW);
  end
endfunction: setup_axi5_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi5_slave_agents_cfg
// Setup the axi5_slave agent(s) configuration with the required values
// and store the handle into the config_db
//--------------------------------------------------------------------------------------------
function void axi5_base_test::setup_axi5_slave_agent_cfg();
  axi5_env_cfg_h.axi5_slave_agent_cfg_h = new[axi5_env_cfg_h.no_of_slaves];
  foreach(axi5_env_cfg_h.axi5_slave_agent_cfg_h[i])begin
    axi5_env_cfg_h.axi5_slave_agent_cfg_h[i] =
    axi5_slave_agent_config::type_id::create($sformatf("axi5_slave_agent_cfg_h[%0d]",i));
    axi5_env_cfg_h.axi5_slave_agent_cfg_h[i].slave_id = i;
    axi5_env_cfg_h.axi5_slave_agent_cfg_h[i].min_address = axi5_env_cfg_h.axi5_master_agent_cfg_h[i].
                                                           master_min_addr_range_array[i];
    axi5_env_cfg_h.axi5_slave_agent_cfg_h[i].max_address = axi5_env_cfg_h.axi5_master_agent_cfg_h[i].
                                                           master_max_addr_range_array[i];
    if(SLAVE_AGENT_ACTIVE === 1) begin
    axi5_env_cfg_h.axi5_slave_agent_cfg_h[i].is_active = uvm_active_passive_enum'(UVM_ACTIVE);
    end
    else begin
    axi5_env_cfg_h.axi5_slave_agent_cfg_h[i].is_active = uvm_active_passive_enum'(UVM_PASSIVE);
    end 
    axi5_env_cfg_h.axi5_slave_agent_cfg_h[i].has_coverage = 1; 
    
    uvm_config_db #(axi5_slave_agent_config)::set(this,"*env*",$sformatf("axi5_slave_agent_config[%0d]",i), axi5_env_cfg_h.axi5_slave_agent_cfg_h[i]);   
   `uvm_info(get_type_name(),$sformatf("\nAXI5_SLAVE_CONFIG[%0d]\n%s",i,axi5_env_cfg_h.axi5_slave_agent_cfg_h[i].sprint()),UVM_LOW);
  end
endfunction: setup_axi5_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
// Used for printing the testbench topology
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_base_test::end_of_elaboration_phase(uvm_phase phase);
  uvm_top.print_topology();
  uvm_test_done.set_drain_time(this,3000ns);
endfunction : end_of_elaboration_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Used for giving basic delay for simulation 
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi5_base_test::run_phase(uvm_phase phase);

  phase.raise_objection(this, "axi5_base_test");

  `uvm_info(get_type_name(), $sformatf("Inside BASE_TEST"), UVM_NONE);
  super.run_phase(phase);
  #100;
  `uvm_info(get_type_name(), $sformatf("Done BASE_TEST"), UVM_NONE);
  phase.drop_objection(this);

endtask : run_phase

`endif

