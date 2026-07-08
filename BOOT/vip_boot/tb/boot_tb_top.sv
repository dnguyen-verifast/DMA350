//------------------------------------------------------------------------------
// boot_tb_top.sv
//
// Top-level testbench: clock/reset, boot interface, DUT stub, SVA bind, and the
// UVM run_test entry point.
//------------------------------------------------------------------------------
`ifndef BOOT_TB_TOP_SV
`define BOOT_TB_TOP_SV

module boot_tb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import boot_test_pkg::*;

  localparam int ADDR_WIDTH = 32;

  logic clk;
  logic resetn;

  // Clock: 100 MHz
  initial clk = 1'b0;
  always #5ns clk = ~clk;

  // Reset: assert for a few cycles, then release. The boot VIP drives the
  // configuration while resetn is LOW so it is stable at the release edge.
  initial begin
    resetn = 1'b0;
    repeat (4) @(posedge clk);
    @(negedge clk);
    resetn = 1'b1;
  end

  // Boot interface.
  boot_if #(.ADDR_WIDTH(ADDR_WIDTH)) bif (.clk(clk), .resetn(resetn));

  // DUT stub drives boot_fetch_started back into the interface.
  boot_dut_stub #(.ADDR_WIDTH(ADDR_WIDTH)) u_dut (
    .clk               (clk),
    .resetn            (resetn),
    .boot_en           (bif.boot_en),
    .boot_addr         (bif.boot_addr),
    .boot_memattr      (bif.boot_memattr),
    .boot_shareattr    (bif.boot_shareattr),
    .boot_fetch_started(bif.boot_fetch_started)
  );

  // Bind the SVA checker onto the interface.
  bind boot_if : bif
    boot_sva #(.ADDR_WIDTH(ADDR_WIDTH), .SECEXT_PRESENT(0)) u_boot_sva (
      .clk               (clk),
      .resetn            (resetn),
      .boot_en           (boot_en),
      .boot_addr         (boot_addr),
      .boot_memattr      (boot_memattr),
      .boot_shareattr    (boot_shareattr),
      .boot_fetch_started(boot_fetch_started)
    );

  initial begin
    uvm_config_db#(virtual boot_if)::set(null, "uvm_test_top", "vif", bif);
    run_test("boot_enabled_test");
  end

  // Safety timeout.
  initial begin
    #100us;
    `uvm_fatal("TB_TOP", "Global timeout")
  end

endmodule : boot_tb_top

`endif // BOOT_TB_TOP_SV
