`ifndef AXI5_SLAVE_PKG_INCLUDED_
`define AXI5_SLAVE_PKG_INCLUDED_

//--------------------------------------------------------------------------------------------
// Package: axi5_slave_pkg
//  Includes all the files related to axi5 axi5_slave
//--------------------------------------------------------------------------------------------
package axi5_slave_pkg;

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
  `include "axi5_slave_mem_region_cfg.sv"
  `include "axi5_slave_mem_map_cfg.sv"
  `include "axi5_slave_memory.sv"
  `include "axi5_slave_tx.sv"
  `include "axi5_slave_agent_config.sv"
  `include "axi5_slave_seq_item_converter.sv"
  `include "axi5_slave_cfg_converter.sv"
  `include "axi5_slave_coverage.sv"
  `include "axi5_slave_write_sequencer.sv"
  `include "axi5_slave_read_sequencer.sv"
  `include "axi5_slave_driver_proxy.sv"
  `include "axi5_slave_monitor_proxy.sv"
  `include "axi5_slave_agent.sv"
  
endpackage : axi5_slave_pkg

`endif
