//==============================================================================
// lpi_qchannel_pkg.sv
// Q-Channel VIP package (ARM IHI 0068D, Chapter 2).
// MASTER and SLAVE each have their OWN driver, monitor and agent. The SEQUENCES
// live in a separate package/folder (lpi_qchannel_seq_pkg, tb/seq); the common
// SCOREBOARD lives in the env.
//==============================================================================
package lpi_qchannel_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ---- shared ----
  `include "lpi_qchannel_types.svh"
  `include "lpi_qchannel_item.sv"
  `include "lpi_qchannel_cfg.sv"

  // ---- MASTER agent = DEVICE (driver + monitor + agent) ----
  `include "lpi_qchannel_master_driver.sv"
  `include "lpi_qchannel_master_monitor.sv"
  `include "lpi_qchannel_master_agent.sv"

  // ---- SLAVE agent = CONTROLLER (driver + monitor + agent) ----
  `include "lpi_qchannel_slave_driver.sv"
  `include "lpi_qchannel_slave_monitor.sv"
  `include "lpi_qchannel_slave_agent.sv"

  // ---- coverage ----
  `include "lpi_qchannel_coverage.sv"

endpackage : lpi_qchannel_pkg
