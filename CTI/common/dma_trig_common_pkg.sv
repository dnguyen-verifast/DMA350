//============================================================================
// dma_trig_common_pkg.sv
// Shared protocol definitions used by BOTH the trig-in and trig-out sides:
// enums, the transaction (packet) and the agent config object. The packet is a
// single type so the scoreboard can correlate requests with the DMAC response.
//
// Compile after uvm_pkg; the interfaces are compiled separately.
//============================================================================
`ifndef DMA_TRIG_COMMON_PKG_SV
`define DMA_TRIG_COMMON_PKG_SV

package dma_trig_common_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "dma_trig_types.sv"
  `include "dma_trig_item.sv"
  `include "dma_trig_cfg.sv"

endpackage : dma_trig_common_pkg

`endif // DMA_TRIG_COMMON_PKG_SV
