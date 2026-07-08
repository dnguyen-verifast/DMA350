`ifndef AXI5_MASTER_PKG_INCLUDED_
`define AXI5_MASTER_PKG_INCLUDED_

//--------------------------------------------------------------------------------------------
// Package: axi5_master_pkg
//  Includes all the files related to axi5 master
//--------------------------------------------------------------------------------------------
package axi5_master_pkg;

  //-------------------------------------------------------
  // Import uvm package
  //-------------------------------------------------------
  `include "uvm_macros.svh"
  import uvm_pkg::*;
 
  // Import axi5_globals_pkg 
  import axi5_globals_pkg::*;
  import axi5_base_tx_pkg::*;

  //-------------------------------------------------------
  // Include all other files
  //-------------------------------------------------------
  `include "axi5_master_agent_config.sv"
  `include "axi5_master_tx.sv"
  `include "axi5_master_seq_item_converter.sv"
  `include "axi5_master_cfg_converter.sv"
  `include "axi5_master_write_sequencer.sv"
  `include "axi5_master_read_sequencer.sv"
  `include "axi5_master_driver_proxy.sv"
  `include "axi5_master_monitor_proxy.sv"
  `include "axi5_master_coverage.sv"
  `include "axi5_master_agent.sv"
  
endpackage : axi5_master_pkg

`endif
