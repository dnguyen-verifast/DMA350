//------------------------------------------------------------------------------
// dma_irq_if.sv
// Interface bat cac tin hieu interrupt output cua DMA-350
//------------------------------------------------------------------------------
interface dma_irq_if #(
  parameter int NUM_CHANNELS   = 8,
  parameter bit SECEXT_PRESENT = 1  // =0 thi irq_comb_sec/irq_sec_viol_err khong ton tai
) (
  input logic clk,
  input logic resetn      // active-LOW reset
);

  // Cac output tu DMAC (chi quan sat -> monitor khong bao gio drive)
  logic [NUM_CHANNELS-1:0] irq_channel;     // interrupt rieng cua tung channel
  logic                    irq_comb_nonsec; // combined Non-secure interrupt
  logic                    irq_comb_sec;    // combined Secure interrupt (chi khi SECEXT_PRESENT=1)
  logic                    irq_sec_viol_err;// security violation interrupt (chi khi SECEXT_PRESENT=1)

  // Clocking block cho monitor: chi sample, khong drive
  clocking mon_cb @(posedge clk);
    input irq_channel;
    input irq_comb_nonsec;
    input irq_comb_sec;
    input irq_sec_viol_err;
  endclocking

  // Modport passive cho monitor
  modport MON (clocking mon_cb, input clk, input resetn);

endinterface : dma_irq_if
