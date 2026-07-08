//------------------------------------------------------------------------------
// boot_test_pkg.sv
//
// Minimal UVM environment and tests demonstrating the boot VIP.
//------------------------------------------------------------------------------
`ifndef BOOT_TEST_PKG_SV
`define BOOT_TEST_PKG_SV

package boot_test_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import boot_pkg::*;

  // ---------------------------------------------------------------------------
  // Environment: a single boot agent.
  // ---------------------------------------------------------------------------
  class boot_env extends uvm_env;
    `uvm_component_utils(boot_env)

    boot_agent     agent;
    boot_agent_cfg cfg;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(boot_agent_cfg)::get(this, "", "cfg", cfg))
        `uvm_fatal(get_type_name(), "boot_agent_cfg not set for env")
      uvm_config_db#(boot_agent_cfg)::set(this, "agent", "cfg", cfg);
      agent = boot_agent::type_id::create("agent", this);
    endfunction
  endclass : boot_env

  // ---------------------------------------------------------------------------
  // Base test: build env, fetch vif, create cfg.
  // ---------------------------------------------------------------------------
  class boot_base_test extends uvm_test;
    `uvm_component_utils(boot_base_test)

    boot_env       env;
    boot_agent_cfg cfg;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      cfg = boot_agent_cfg::type_id::create("cfg");
      if (!uvm_config_db#(virtual boot_if)::get(this, "", "vif", cfg.vif))
        `uvm_fatal(get_type_name(), "virtual boot_if not set")
      cfg.is_active      = UVM_ACTIVE;
      cfg.addr_width     = 32;
      cfg.secext_present = 0;
      configure(cfg);
      uvm_config_db#(boot_agent_cfg)::set(this, "env", "cfg", cfg);
      env = boot_env::type_id::create("env", this);
    endfunction

    // Hook for derived tests to tweak the config.
    virtual function void configure(boot_agent_cfg cfg);
    endfunction
  endclass : boot_base_test

  // ---------------------------------------------------------------------------
  // Test: randomized enabled boot.
  // ---------------------------------------------------------------------------
  class boot_enabled_test extends boot_base_test;
    `uvm_component_utils(boot_enabled_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      boot_enabled_seq seq = boot_enabled_seq::type_id::create("seq");
      phase.raise_objection(this);
      seq.addr_width     = cfg.addr_width;
      seq.secext_present = cfg.secext_present;
      seq.secure_base    = cfg.secure_base;
      seq.secure_limit   = cfg.secure_limit;
      seq.start(env.agent.sqr);
      // Allow the boot fetch window to be exercised by the DUT stub.
      #500ns;
      phase.drop_objection(this);
    endtask
  endclass : boot_enabled_test

  // ---------------------------------------------------------------------------
  // Test: Secure boot (SECEXT) directed to a Secure address.
  // ---------------------------------------------------------------------------
  class boot_secure_test extends boot_base_test;
    `uvm_component_utils(boot_secure_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void configure(boot_agent_cfg cfg);
      cfg.secext_present = 1;
      cfg.secure_base    = 64'h5000_0000;
      cfg.secure_limit   = 64'h6000_0000;
    endfunction

    task run_phase(uvm_phase phase);
      boot_directed_seq seq = boot_directed_seq::type_id::create("seq");
      phase.raise_objection(this);
      seq.addr_width     = cfg.addr_width;
      seq.secext_present = cfg.secext_present;
      seq.secure_base    = cfg.secure_base;
      seq.secure_limit   = cfg.secure_limit;
      seq.addr           = (64'h5000_1000) >> 2; // word-aligned, in Secure region
      seq.start(env.agent.sqr);
      #500ns;
      phase.drop_objection(this);
    endtask
  endclass : boot_secure_test

endpackage : boot_test_pkg

`endif // BOOT_TEST_PKG_SV
