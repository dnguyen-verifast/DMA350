//==============================================================================
// crlp_pkg.sv : Clock / Reset / Low-Power (Q-Channel + P-Channel) UVM agent
//==============================================================================
`ifndef CRLP_PKG_SV
`define CRLP_PKG_SV

package crlp_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "crlp_types.svh"
  `include "crlp_config.svh"
  `include "crlp_seq_item.svh"
  `include "crlp_sequencer.svh"
  `include "crlp_driver.svh"
  `include "crlp_monitor.svh"
  `include "crlp_coverage.svh"
  `include "crlp_agent.svh"
  `include "crlp_seq_lib.svh"

endpackage

`endif // CRLP_PKG_SV
