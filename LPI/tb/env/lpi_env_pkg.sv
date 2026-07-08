//==============================================================================
// lpi_env_pkg.sv
// Top environment package. Classes are split into individual files and only
// included here. Holds the virtual SEQUENCER and the COMMON SCOREBOARD shared
// by both interfaces. The virtual SEQUENCES live in a separate package.
//==============================================================================
package lpi_env_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import lpi_qchannel_pkg::*;
  import lpi_pchannel_pkg::*;

  `include "lpi_env_cfg.sv"
  `include "lpi_virtual_sequencer.sv"
  `include "lpi_scoreboard.sv"        // ONE scoreboard for both Q and P
  `include "lpi_env.sv"

endpackage : lpi_env_pkg
