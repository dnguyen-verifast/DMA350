//------------------------------------------------------------------------------
// boot_if.sv
//
// SystemVerilog interface for the Arm CoreLink DMA-350 automatic boot
// configuration interface (TRM 102482, Table A-11 "Configuration signals").
//
// All boot_* signals are *inputs to the DMAC*. They are static configuration
// values that:
//   * must be stable when the active-LOW reset (resetn) is deasserted, and
//   * must remain stable until fetching of the boot command has started
//     (TRM section 4.9.1 "Automatic boot interface").
//
// If boot_en is LOW, automatic booting is disabled and the other boot signals
// are ignored by the DMAC.
//------------------------------------------------------------------------------
`ifndef BOOT_IF_SV
`define BOOT_IF_SV

`timescale 1ns/1ps

interface boot_if #(
  // Address width of the DMAC (DMA_BUILDCFG0.ADDR_WIDTH + 1). 32 or 64.
  parameter int ADDR_WIDTH = 32
) (
  input logic clk,
  input logic resetn   // active-LOW reset (shared DMAC reset)
);

  // --------------------------------------------------------------------------
  // Table A-11 configuration signals (DUT inputs / VIP outputs)
  // --------------------------------------------------------------------------
  // boot_addr is word-aligned: only [ADDR_WIDTH-1:2] exist on the bus.
  logic                      boot_en;
  logic [ADDR_WIDTH-1:2]     boot_addr;
  logic [7:0]                boot_memattr;
  logic [1:0]                boot_shareattr;

  // --------------------------------------------------------------------------
  // Sideband observation signal (not part of Table A-11).
  //
  // The boot stability window closes when the DMAC starts fetching the boot
  // command descriptor. The DMAC has no dedicated "boot fetch started" pin, so
  // the integration testbench must connect this to a derived indication, e.g.
  // the first command-link read on AXI5 M0 for channel 0
  // (arvalid_m0 & arready_m0 & arcmdlink_m0). When not available, set
  // boot_agent_cfg.check_stability_window = 0 to disable the related checks.
  // --------------------------------------------------------------------------
  logic                      boot_fetch_started;

  // --------------------------------------------------------------------------
  // Clocking blocks
  // --------------------------------------------------------------------------
  clocking drv_cb @(posedge clk);
    default output #1ns;
    output boot_en, boot_addr, boot_memattr, boot_shareattr;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input boot_en, boot_addr, boot_memattr, boot_shareattr, boot_fetch_started;
  endclocking

  modport drv (clocking drv_cb, input clk, input resetn);
  modport mon (clocking mon_cb, input clk, input resetn);

endinterface : boot_if

`endif // BOOT_IF_SV
