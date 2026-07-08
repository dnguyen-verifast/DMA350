//==============================================================================
// crlp_config.svh : configuration object for the CRLP agent
//==============================================================================
`ifndef CRLP_CONFIG_SVH
`define CRLP_CONFIG_SVH

class crlp_config extends uvm_object;
  `uvm_object_utils(crlp_config)

  // Virtual interface handle (set from the test/top via config_db).
  virtual crlp_if vif;

  // Active (drives) or passive (monitor only).
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // Enable functional coverage collection.
  bit has_coverage = 1;

  // ---- Clock generation -----------------------------------------------------
  // Full clock period in ps (e.g. 10000 ps = 100 MHz).
  time clk_period_ps = 10_000;
  // Start the clock automatically at the beginning of run_phase.
  bit  auto_start_clock = 1;

  // ---- Reset ----------------------------------------------------------------
  int unsigned reset_assert_cycles = 5;   // how long resetn is held LOW

  // ---- Static clock enables reset value ------------------------------------
  bit init_aclken_m0 = 1;
  bit init_aclken_m1 = 1;
  bit init_pclken    = 1;

  // ---- Low-power handshake timeouts (in clock cycles) ----------------------
  int unsigned qch_timeout_cycles = 64;
  int unsigned pch_timeout_cycles = 64;

  function new(string name = "crlp_config");
    super.new(name);
  endfunction

  // Convenience: half period as a time value.
  function time half_period();
    return clk_period_ps / 2;
  endfunction

endclass

`endif // CRLP_CONFIG_SVH
