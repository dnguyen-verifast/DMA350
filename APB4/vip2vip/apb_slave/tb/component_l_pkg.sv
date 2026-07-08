`ifndef COMPONENT_L_PKG_INCLUDE_
`define COMPONENT_L_PKG_INCLUDE_
package component_l_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "apb_seq_item_slave.sv"
  `include "apb_sequencer_slave.sv"
  `include "apb_driver_slave.sv"
  `include "apb_monitor_slave.sv"
  `include "apb_agent_slave.sv"
endpackage
`endif
