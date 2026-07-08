//------------------------------------------------------------------------------
// dma_irq_pkg.sv
// Package gom cac class cua IRQ agent (monitor-only) cho DMA-350.
// Bien dich file nay sau khi da compile interface dma_irq_if.sv.
//------------------------------------------------------------------------------
package dma_irq_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "dma_irq_item.sv"
  `include "dma_irq_config.sv"
  `include "dma_irq_monitor.sv"
  `include "dma_irq_agent.sv"

endpackage : dma_irq_pkg
