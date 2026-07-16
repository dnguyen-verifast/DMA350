//============================================================================
// dma_trig_vseq_pkg.sv
// Virtual sequence package. Imports common/in/out/env. Compile after them.
//============================================================================
`ifndef DMA_TRIG_VSEQ_PKG_SV
`define DMA_TRIG_VSEQ_PKG_SV

package dma_trig_vseq_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import dma_trig_common_pkg::*;
  import dma_trig_in_pkg::*;
  import dma_trig_out_pkg::*;
  import dma_trig_env_pkg::*;

  `include "dma_trig_vseq_base.sv"
  `include "dma_trig_smoke_vseq.sv"
  `include "dma_trig_distribute_vseq.sv"
  `include "dma_trig_stall_vseq.sv"
  `include "dma_trig_errinj_vseq.sv"

endpackage : dma_trig_vseq_pkg

`endif // DMA_TRIG_VSEQ_PKG_SV
