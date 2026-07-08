//==============================================================================
// lpi_pchannel_pkg.sv
// P-Channel VIP package (ARM IHI 0068D, Chapter 3).
// MASTER and SLAVE each have their OWN driver, monitor and agent. The SEQUENCES
// live in a separate package/folder (lpi_pchannel_seq_pkg, tb/seq); the common
// SCOREBOARD lives in the env.
//==============================================================================
`include "lpi_defs.svh"

package lpi_pchannel_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ---- shared ----
  `include "lpi_pchannel_types.svh"
  `include "lpi_pchannel_item.sv"
  `include "lpi_pchannel_cfg.sv"

  // ---- MASTER agent = CONTROLLER (driver + monitor + agent) ----
  `include "lpi_pchannel_master_driver.sv"
  `include "lpi_pchannel_master_monitor.sv"
  `include "lpi_pchannel_master_agent.sv"

  // ---- SLAVE agent = DEVICE (driver + monitor + agent) ----
  `include "lpi_pchannel_slave_driver.sv"
  `include "lpi_pchannel_slave_monitor.sv"
  `include "lpi_pchannel_slave_agent.sv"

  // ---- coverage ----
  `include "lpi_pchannel_coverage.sv"

endpackage : lpi_pchannel_pkg
