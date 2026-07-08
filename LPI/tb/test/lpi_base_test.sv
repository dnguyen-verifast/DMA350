//==============================================================================
// lpi_base_test.sv  -  base test : builds env + env config
//==============================================================================
class lpi_base_test extends uvm_test;
  `uvm_component_utils(lpi_base_test)
  lpi_env      env;
  lpi_env_cfg  cfg;
  int unsigned n_req = 30;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = lpi_env_cfg::type_id::create("cfg");
    if (!uvm_config_db#(virtual lpi_qchannel_if)::get(this,"","qvif",cfg.qvif))
      `uvm_fatal(get_type_name(),"qvif not set")
    if (!uvm_config_db#(virtual lpi_pchannel_if)::get(this,"","pvif",cfg.pvif))
      `uvm_fatal(get_type_name(),"pvif not set")
    configure(cfg);
    uvm_config_db#(lpi_env_cfg)::set(this,"env","cfg",cfg);
    env = lpi_env::type_id::create("env", this);
  endfunction

  // override in derived tests to enable/disable channels
  virtual function void configure(lpi_env_cfg c);
    c.enable_qchannel = 1;
    c.enable_pchannel = 1;
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction
endclass
