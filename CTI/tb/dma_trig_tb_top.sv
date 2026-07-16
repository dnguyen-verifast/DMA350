//============================================================================
// dma_trig_tb_top.sv
// Standalone testbench for the peripheral trigger VIP. Instantiates NUM_IN
// trigger-in ports and NUM_OUT trigger-out ports, each with a behavioural DMA
// stub closing the handshake. The VIP (requester on in, responder on out) is
// built by the env, sized from config_db ints.
//============================================================================
`timescale 1ns/1ps

module dma_trig_tb_top;

  import uvm_pkg::*;
  import dma_trig_common_pkg::*;
  import dma_trig_in_pkg::*;
  import dma_trig_out_pkg::*;
  import dma_trig_env_pkg::*;
  import dma_trig_vseq_pkg::*;
  `include "uvm_macros.svh"

  // ---- tests (base first, then concrete tests) ----
  `include "test/dma_trig_base_test.sv"
  `include "test/dma_trig_smoke_test.sv"
  `include "test/dma_trig_distribute_test.sv"
  `include "test/dma_trig_flow_test.sv"
  `include "test/dma_trig_stall_test.sv"
  `include "test/dma_trig_errinj_test.sv"

  localparam int unsigned NUM_IN  = 2;   // NUM_TRIGGER_IN
  localparam int unsigned NUM_OUT = 2;   // NUM_TRIGGER_OUT

  // ---- clock & reset ----
  logic clk = 0, resetn = 0;
  always #5 clk = ~clk;
  initial begin resetn = 0; repeat (5) @(posedge clk); resetn <= 1'b1; end

  // ---- trigger-in ports (VIP = requester, stub = DMAC responder) ----
  // Dung interface TONG dma_trig_if; day la cong in-only nen stub tie
  // trig_out_req = 0 (luong auto-ack trong driver khong kich hoat).
  genvar gi;
  generate
    for (gi = 0; gi < NUM_IN; gi++) begin : gin
      dma_trig_if  u_if (.clk(clk), .resetn(resetn));
      dma_trig_in_dmac u_dmac (.vif(u_if));
      initial uvm_config_db#(virtual dma_trig_if)::set(
                null, "*", $sformatf("trig_in_vif_%0d", gi), u_if);
    end
  endgenerate

  // ---- trigger-out ports (VIP = responder, stub = DMAC requester) ----
  generate
    for (gi = 0; gi < NUM_OUT; gi++) begin : gout
      dma_trig_out_if  u_if (.clk(clk), .resetn(resetn));
      dma_trig_out_dmac u_dmac (.vif(u_if));
      initial uvm_config_db#(virtual dma_trig_out_if)::set(
                null, "*", $sformatf("trig_out_vif_%0d", gi), u_if);
    end
  endgenerate

  // ---- publish counts ----
  initial begin
    uvm_config_db#(int unsigned)::set(null, "*", "num_trig_in",  NUM_IN);
    uvm_config_db#(int unsigned)::set(null, "*", "num_trig_out", NUM_OUT);
  end

  // ---- run ----
  initial run_test("dma_trig_smoke_test");

  // ---- safety timeout ----
  initial begin #2ms; `uvm_fatal("TB_TOP", "Global timeout reached") end

  initial if ($test$plusargs("DUMP")) begin
    $dumpfile("dma_trig.vcd"); $dumpvars(0, dma_trig_tb_top);
  end

endmodule : dma_trig_tb_top
