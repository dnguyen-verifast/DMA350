//==============================================================================
// dma350_sc_pkg.sv
//------------------------------------------------------------------------------
// Package for the DMA-350 status/control agent. Include this after the
// interface file has been compiled/added to the file list. Compile order of
// the `include's below is significant.
//
// The MAX_* macros must match those the interface was compiled with, since the
// item/cfg size their status vectors from them.
//==============================================================================
`ifndef DMA350_SC_PKG__SV
`define DMA350_SC_PKG__SV

`ifndef DMA350_SC_MAX_CHANNELS
  `define DMA350_SC_MAX_CHANNELS 8
`endif
`ifndef DMA350_SC_MAX_GPO_WIDTH
  `define DMA350_SC_MAX_GPO_WIDTH 32
`endif

package dma350_sc_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ---- config / item ----
  `include "dma350_sc_cfg.sv"
  `include "dma350_sc_item.sv"

  // ---- components ----
  `include "dma350_sc_sequencer.sv"
  `include "dma350_sc_driver.sv"
  `include "dma350_sc_monitor.sv"
  `include "dma350_sc_coverage.sv"
  `include "dma350_sc_agent.sv"

  // ---- sequences ----
  `include "dma350_sc_base_seq.sv"
  `include "dma350_sc_stop_seq.sv"
  `include "dma350_sc_pause_seq.sv"
  `include "dma350_sc_cti_seq.sv"
  `include "dma350_sc_gpo_check_seq.sv"
  `include "dma350_sc_corner_seqs.sv"

endpackage : dma350_sc_pkg

`endif // DMA350_SC_PKG__SV
