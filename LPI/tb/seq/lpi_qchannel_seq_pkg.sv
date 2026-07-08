//==============================================================================
// lpi_qchannel_seq_pkg.sv
// Q-Channel sequence library - all child sequences live here, separate from the
// agent. Imports lpi_qchannel_pkg for the item/enum types.
//==============================================================================
package lpi_qchannel_seq_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import lpi_qchannel_pkg::*;

  // device responder (base + scenarios)
  `include "lpi_qchannel_master_seq.sv"
  `include "lpi_qchannel_master_accept_seq.sv"
  `include "lpi_qchannel_master_deny_seq.sv"
  // controller initiator
  `include "lpi_qchannel_slave_seq.sv"

endpackage : lpi_qchannel_seq_pkg
