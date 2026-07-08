`ifndef AXI5_ENV_PKG_INCLUDED_
`define AXI5_ENV_PKG_INCLUDED_

//--------------------------------------------------------------------------------------------
// Package: axi5_env_pkg
// Includes all the files related to axi5 env
//--------------------------------------------------------------------------------------------
package axi5_env_pkg;
  
  //Import uvm package
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  //Importing the required packages
  import axi5_globals_pkg::*;
  import axi5_master_pkg::*;
  import axi5_slave_pkg::*;

  //Include all other files
  `include "axi5_env_config.sv"
  `include "axi5_virtual_sequencer.sv"
  `include "axi5_scoreboard.sv"
  `include "axi5_env.sv"

endpackage : axi5_env_pkg

`endif
