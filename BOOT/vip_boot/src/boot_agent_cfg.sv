//------------------------------------------------------------------------------
// boot_agent_cfg.sv
//
// Configuration object for the boot VIP agent.
//------------------------------------------------------------------------------
`ifndef BOOT_AGENT_CFG_SV
`define BOOT_AGENT_CFG_SV

class boot_agent_cfg extends uvm_object;

  // Virtual interface handle for the agent.
  virtual boot_if vif;

  // ACTIVE  -> driver + sequencer + monitor (drives boot_* inputs)
  // PASSIVE -> monitor only (observes a third-party driver)
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // DMAC build parameters relevant to checking.
  int unsigned addr_width    = 32;  // DMA_BUILDCFG0.ADDR_WIDTH + 1
  bit          secext_present = 0;   // DMA_BUILDCFG2.HAS_TZ

  // Secure region used to check boot_addr when secext_present == 1.
  bit [63:0]   secure_base    = '0;
  bit [63:0]   secure_limit   = '1;

  // Enable protocol/coverage features.
  bit          enable_coverage          = 1;
  // Check that boot_* are stable from reset deassertion until
  // boot_fetch_started (requires boot_fetch_started to be wired up).
  bit          check_stability_window   = 1;

  `uvm_object_utils_begin(boot_agent_cfg)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
    `uvm_field_int (addr_width,             UVM_DEFAULT)
    `uvm_field_int (secext_present,         UVM_DEFAULT)
    `uvm_field_int (secure_base,            UVM_DEFAULT | UVM_HEX)
    `uvm_field_int (secure_limit,           UVM_DEFAULT | UVM_HEX)
    `uvm_field_int (enable_coverage,        UVM_DEFAULT)
    `uvm_field_int (check_stability_window, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "boot_agent_cfg");
    super.new(name);
  endfunction

endclass : boot_agent_cfg

`endif // BOOT_AGENT_CFG_SV
