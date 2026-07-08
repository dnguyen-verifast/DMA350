//==============================================================================
// tb_top.sv
// Top-level harness for the LPI VIP-to-VIP testbench.
// Generates clock + reset, instantiates the Q-Channel and P-Channel interfaces,
// publishes their virtual handles, and starts UVM.
//==============================================================================
`include "lpi_defs.svh"

module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import lpi_test_pkg::*;

  // ---- Clock / reset ----
  logic clk;
  logic resetn;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;        // 100 MHz
  end

  initial begin
    resetn = 1'b0;
    repeat (5) @(posedge clk);
    resetn = 1'b1;                // synchronous-ish deassertion
  end

  // ---- Interfaces (VIP-to-VIP: no DUT, the two VIPs share these wires) ----
  lpi_qchannel_if q_if (.clk(clk), .resetn(resetn));
  lpi_pchannel_if p_if (.clk(clk), .resetn(resetn));

  // ---- Publish virtual interfaces and run ----
  initial begin
    uvm_config_db#(virtual lpi_qchannel_if)::set(null, "uvm_test_top", "qvif", q_if);
    uvm_config_db#(virtual lpi_pchannel_if)::set(null, "uvm_test_top", "pvif", p_if);
    run_test("lpi_smoke_test");
  end

  // ---- Global watchdog ----
  initial begin
    #200000;
    `uvm_fatal("TB_TOP", "Global timeout reached")
  end

  // ---- Waves ----
  initial begin
    $dumpfile("lpi_tb.vcd");
    $dumpvars(0, tb_top);
  end

endmodule : tb_top
