//------------------------------------------------------------------------------
// boot_pkg.sv
//
// UVM package for the DMA-350 boot configuration Verification IP.
//------------------------------------------------------------------------------
`ifndef BOOT_PKG_SV
`define BOOT_PKG_SV

package boot_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "boot_types.svh"
  `include "boot_seq_item.sv"
  `include "boot_agent_cfg.sv"
  `include "boot_driver.sv"
  `include "boot_monitor.sv"
  `include "boot_coverage.sv"
  `include "boot_agent.sv"
  `include "boot_seq_lib.sv"

endpackage : boot_pkg

`endif // BOOT_PKG_SV
