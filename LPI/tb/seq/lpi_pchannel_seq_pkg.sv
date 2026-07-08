//==============================================================================
// lpi_pchannel_seq_pkg.sv
// P-Channel sequence library - all child sequences live here, separate from the
// agent. Imports lpi_pchannel_pkg for the item/enum types.
//==============================================================================
`include "lpi_defs.svh"

package lpi_pchannel_seq_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import lpi_pchannel_pkg::*;

  // controller initiator (base + scenarios)
  `include "lpi_pchannel_master_seq.sv"
  `include "lpi_pchannel_master_walk_seq.sv"
  // device responder (base + scenarios)
  `include "lpi_pchannel_slave_seq.sv"
  `include "lpi_pchannel_slave_accept_seq.sv"
  `include "lpi_pchannel_slave_deny_seq.sv"

endpackage : lpi_pchannel_seq_pkg
