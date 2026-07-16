//============================================================================
// dma_trig_out_pkg.sv
// Trigger-OUT (responder) agent package. Imports common. Compile after
// dma_trig_common_pkg; the interface dma_trig_out_if.sv is compiled separately.
//============================================================================
`ifndef DMA_TRIG_OUT_PKG_SV
`define DMA_TRIG_OUT_PKG_SV

package dma_trig_out_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import dma_trig_common_pkg::*;

  `include "dma_trig_out_sequencer.sv"
  `include "dma_trig_out_driver.sv"
  `include "dma_trig_out_monitor.sv"
  `include "dma_trig_out_coverage.sv"
  `include "dma_trig_out_agent.sv"

  // ---- sequences ----
  `include "seq/dma_trig_out_base_seq.sv"
  `include "seq/dma_trig_out_ack_seq.sv"
  `include "seq/dma_trig_out_stall_seq.sv"
  `include "seq/dma_trig_out_swack_seq.sv"

endpackage : dma_trig_out_pkg

`endif // DMA_TRIG_OUT_PKG_SV
