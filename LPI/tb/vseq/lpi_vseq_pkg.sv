//==============================================================================
// lpi_vseq_pkg.sv
// Virtual sequence package - lives in tb/vseq, separate from the agents.
// Imports the channel VIPs (for the sub-sequence types) and the env package
// (for the lpi_virtual_sequencer type used by `uvm_declare_p_sequencer).
//==============================================================================
package lpi_vseq_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import lpi_qchannel_pkg::*;
  import lpi_pchannel_pkg::*;
  import lpi_qchannel_seq_pkg::*;   // child sequences (separate folder tb/seq)
  import lpi_pchannel_seq_pkg::*;
  import lpi_env_pkg::*;

  `include "lpi_base_vseq.sv"
  `include "lpi_sanity_vseq.sv"
  `include "lpi_smoke_vseq.sv"
  // per-scenario virtual sequences (each drives its own dedicated child seqs)
  `include "lpi_q_accept_vseq.sv"
  `include "lpi_q_deny_vseq.sv"
  `include "lpi_p_accept_vseq.sv"
  `include "lpi_p_deny_vseq.sv"
  `include "lpi_p_walk_vseq.sv"

endpackage : lpi_vseq_pkg
