`ifndef COMPONENT_M_PKG_INCLUDE_
`define COMPONENT_M_PKG_INCLUDE_
package component_m_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "apb_seq_item_master.sv"
  `include "apb_sequencer_master.sv"
  `include "apb_driver_master.sv"
  `include "apb_monitor_master.sv"
  `include "apb_agent_master.sv"
endpackage
`endif
