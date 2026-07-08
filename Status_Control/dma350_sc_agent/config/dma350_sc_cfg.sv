//==============================================================================
// dma350_sc_cfg.sv
//------------------------------------------------------------------------------
// Configuration object for the status/control agent.
//
// This object is the single place that captures the *build-dependent*
// existence of signals described in Table A-10, so the same RTL/vif can be
// reused across DMA-350 builds:
//
//   secext_present  -> gate the *_sec stop/pause pairs and ch_nonsec
//   num_channels    -> how many ch_* / gpo_ch ports are real  (1..8)
//   gpo_width       -> width of each gpo_ch port               (0..32)
//   ch_gpo_mask[N]  -> whether channel N owns a gpo_ch port    (CH_GPO_MASK)
//
// Set these in the env/test build_phase before the agent is built and push it
// down via uvm_config_db#(dma350_sc_cfg).
//==============================================================================
`ifndef DMA350_SC_CFG__SV
`define DMA350_SC_CFG__SV

class dma350_sc_cfg extends uvm_object;
  `uvm_object_utils(dma350_sc_cfg)

  // ---- agent role --------------------------------------------------------
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // ---- build-dependent signal existence (mirror of RTL config params) ----
  bit          secext_present = 1'b1;   // SECEXT_PRESENT
  int unsigned num_channels   = 8;      // NUM_CHANNELS   (1..8)
  int unsigned gpo_width       = 32;    // GPO_WIDTH      (0..32)
  // Per-channel GPO presence. ch_gpo_mask[N]=1 => gpo_ch_<N> exists.
  bit          ch_gpo_mask [`DMA350_SC_MAX_CHANNELS];

  // ---- protocol timing knobs (in clk cycles) -----------------------------
  // Bound the wait for a 4-phase ack so a hung DUT fails the test instead of
  // hanging the sim. 0 => wait forever.
  int unsigned handshake_timeout = 2000;
  // Width of the restart_req / (observed) halted pulse.
  int unsigned pulse_len         = 1;

  // ---- coverage / checks enables -----------------------------------------
  bit enable_protocol_checks = 1'b1;   // monitor SVA-style handshake checks
  bit enable_coverage        = 1'b1;

  function new(string name = "dma350_sc_cfg");
    super.new(name);
    foreach (ch_gpo_mask[i]) ch_gpo_mask[i] = 1'b1; // default: all present
  endfunction

  // Convenience: does channel N expose a GPO port in this build?
  function bit has_gpo(int unsigned ch);
    if (gpo_width == 0)               return 1'b0;
    if (ch >= num_channels)           return 1'b0;
    return ch_gpo_mask[ch];
  endfunction

  // Convenience: is the Secure stop/pause path and ch_nonsec present?
  function bit has_secure();
    return secext_present;
  endfunction

  function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_string ("is_active",       is_active.name());
    printer.print_field  ("secext_present",  secext_present, 1, UVM_BIN);
    printer.print_field  ("num_channels",    num_channels,  32, UVM_DEC);
    printer.print_field  ("gpo_width",       gpo_width,     32, UVM_DEC);
    printer.print_field  ("handshake_timeout", handshake_timeout, 32, UVM_DEC);
  endfunction

endclass : dma350_sc_cfg

`endif // DMA350_SC_CFG__SV
