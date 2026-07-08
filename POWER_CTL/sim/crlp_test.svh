//==============================================================================
// crlp_test.svh : example environment + test using the CRLP agent
//==============================================================================
`ifndef CRLP_TEST_SVH
`define CRLP_TEST_SVH

// Simple environment wrapping a single CRLP agent.
class crlp_env extends uvm_env;
  `uvm_component_utils(crlp_env)
  crlp_agent  agent;
  crlp_config cfg;

  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(crlp_config)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "cfg not set")
    uvm_config_db#(crlp_config)::set(this, "agent", "cfg", cfg);
    agent = crlp_agent::type_id::create("agent", this);
  endfunction
endclass

// Base test : builds env, gets vif from top, drives the full low-power flow.
class crlp_base_test extends uvm_test;
  `uvm_component_utils(crlp_base_test)
  crlp_env    env;
  crlp_config cfg;

  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = crlp_config::type_id::create("cfg");
    if (!uvm_config_db#(virtual crlp_if)::get(this, "", "vif", cfg.vif))
      `uvm_fatal(get_type_name(), "virtual crlp_if not set")
    cfg.is_active        = UVM_ACTIVE;
    cfg.clk_period_ps    = 10_000;      // 100 MHz
    cfg.auto_start_clock = 0;           // POR sequence starts it explicitly
    uvm_config_db#(crlp_config)::set(this, "env", "cfg", cfg);
    env = crlp_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    crlp_lowpower_flow_seq seq;
    phase.raise_objection(this);
    seq = crlp_lowpower_flow_seq::type_id::create("seq");
    seq.start(env.agent.sqr);
    #(20 * cfg.clk_period_ps);
    phase.drop_objection(this);
  endtask
endclass

`endif // CRLP_TEST_SVH
