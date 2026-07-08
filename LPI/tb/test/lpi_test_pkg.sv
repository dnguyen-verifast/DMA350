//==============================================================================
// lpi_test_pkg.sv
// Test package. Tests are split into individual files and included here.
// Virtual sequences come from the separate lpi_vseq_pkg.
//==============================================================================
package lpi_test_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import lpi_qchannel_pkg::*;
  import lpi_pchannel_pkg::*;
  import lpi_env_pkg::*;
  import lpi_vseq_pkg::*;

  `include "lpi_base_test.sv"
  `include "lpi_sanity_test.sv"
  `include "lpi_smoke_test.sv"
  `include "lpi_qchannel_test.sv"
  `include "lpi_pchannel_test.sv"
  // per-scenario tests
  `include "lpi_q_accept_test.sv"
  `include "lpi_q_deny_test.sv"
  `include "lpi_p_accept_test.sv"
  `include "lpi_p_deny_test.sv"
  `include "lpi_p_walk_test.sv"

endpackage : lpi_test_pkg
