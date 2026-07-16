//============================================================================
// dma_trig_env_pkg.sv
// Environment package: scoreboard, virtual sequencer and env. Imports the
// common, trig-in and trig-out packages.
//
// Compile after dma_trig_common_pkg, dma_trig_in_pkg, dma_trig_out_pkg.
//============================================================================
`ifndef DMA_TRIG_ENV_PKG_SV
`define DMA_TRIG_ENV_PKG_SV

package dma_trig_env_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import dma_trig_common_pkg::*;
  import dma_trig_in_pkg::*;
  import dma_trig_out_pkg::*;

  `include "dma_trig_scoreboard.sv"
  `include "dma_trig_vseqr.sv"
  `include "dma_trig_env.sv"

endpackage : dma_trig_env_pkg

`endif // DMA_TRIG_ENV_PKG_SV
