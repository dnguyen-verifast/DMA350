//==============================================================================
// dma350_sc_tb_top.sv
//------------------------------------------------------------------------------
// Standalone example top: clock/reset, interface instance, config_db handoff of
// the vif to the agent, and run_test(). Replace `dma350_dut_stub` with the real
// DMA-350 (or a bind) and connect the control/status ports.
//==============================================================================
`ifndef DMA350_SC_TB_TOP__SV
`define DMA350_SC_TB_TOP__SV

// Keep the vif sizing macros consistent with the package.
`define DMA350_SC_MAX_CHANNELS  8
`define DMA350_SC_MAX_GPO_WIDTH 32

module dma350_sc_tb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import dma350_sc_pkg::*;

  // ---- clock / reset -----------------------------------------------------
  logic clk = 0;
  logic resetn = 0;
  always #5 clk = ~clk;      // 100 MHz
  initial begin
    resetn = 0;
    repeat (5) @(posedge clk);
    resetn = 1;
  end

  // ---- interface ---------------------------------------------------------
  dma350_sc_if u_if (.clk(clk), .resetn(resetn));

  // ---- DUT (stub) --------------------------------------------------------
  // Replace with the real DMA-350 control/status ports. The stub just keeps
  // outputs benign so the example elaborates and runs.
  dma350_dut_stub u_dut (
    .clk                     (clk),
    .resetn                  (resetn),
    // stop
    .allch_stop_req_nonsec   (u_if.allch_stop_req_nonsec),
    .allch_stop_ack_nonsec   (u_if.allch_stop_ack_nonsec),
    .allch_stop_req_sec      (u_if.allch_stop_req_sec),
    .allch_stop_ack_sec      (u_if.allch_stop_ack_sec),
    // pause
    .allch_pause_req_nonsec  (u_if.allch_pause_req_nonsec),
    .allch_pause_ack_nonsec  (u_if.allch_pause_ack_nonsec),
    .allch_pause_req_sec     (u_if.allch_pause_req_sec),
    .allch_pause_ack_sec     (u_if.allch_pause_ack_sec),
    // cti
    .halt_req                (u_if.halt_req),
    .restart_req             (u_if.restart_req),
    .halted                  (u_if.halted),
    // status
    .ch_enabled              (u_if.ch_enabled),
    .ch_err                  (u_if.ch_err),
    .ch_stopped              (u_if.ch_stopped),
    .ch_paused               (u_if.ch_paused),
    .ch_priv                 (u_if.ch_priv),
    .ch_nonsec               (u_if.ch_nonsec),
    .gpo_ch                  (u_if.gpo_ch)
  );

  // ---- config_db: hand the vif modports to the agent ---------------------
  initial begin
    uvm_config_db#(virtual dma350_sc_if.DRV)::set(null, "uvm_test_top.env.agent.drv", "vif", u_if.DRV);
    uvm_config_db#(virtual dma350_sc_if.MON)::set(null, "uvm_test_top.env.agent.mon", "vif", u_if.MON);
    run_test("dma350_sc_smoke_test");
  end

endmodule : dma350_sc_tb_top


//------------------------------------------------------------------------------
// Minimal behavioural stub so the example elaborates. NOT a model of the DMAC —
// it just closes the stop/pause 4-phase handshakes and pulses `halted` after a
// halt so the monitor/driver have something to synchronise to.
//------------------------------------------------------------------------------
module dma350_dut_stub (
  input  logic clk, resetn,
  input  logic allch_stop_req_nonsec,  output logic allch_stop_ack_nonsec,
  input  logic allch_stop_req_sec,     output logic allch_stop_ack_sec,
  input  logic allch_pause_req_nonsec, output logic allch_pause_ack_nonsec,
  input  logic allch_pause_req_sec,    output logic allch_pause_ack_sec,
  input  logic halt_req, input logic restart_req, output logic halted,
  output logic [`DMA350_SC_MAX_CHANNELS-1:0] ch_enabled, ch_err, ch_stopped,
                                             ch_paused, ch_priv, ch_nonsec,
  output logic [`DMA350_SC_MAX_GPO_WIDTH-1:0] gpo_ch [`DMA350_SC_MAX_CHANNELS]
);
  // trivial 1-cycle-latency ack echoes (4-phase closes because ack follows req)
  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      {allch_stop_ack_nonsec, allch_stop_ack_sec,
       allch_pause_ack_nonsec, allch_pause_ack_sec, halted} <= '0;
      {ch_enabled, ch_err, ch_stopped, ch_paused, ch_priv, ch_nonsec} <= '0;
      foreach (gpo_ch[i]) gpo_ch[i] <= '0;
    end
    else begin
      allch_stop_ack_nonsec  <= allch_stop_req_nonsec;
      allch_stop_ack_sec     <= allch_stop_req_sec;
      allch_pause_ack_nonsec <= allch_pause_req_nonsec;
      allch_pause_ack_sec    <= allch_pause_req_sec;
      halted                 <= halt_req & ~restart_req; // crude pulse-ish
      // reflect stop/pause into status bits for the example
      ch_stopped <= {`DMA350_SC_MAX_CHANNELS{allch_stop_ack_nonsec}};
      ch_paused  <= {`DMA350_SC_MAX_CHANNELS{allch_pause_ack_nonsec}};
    end
  end
endmodule

`endif // DMA350_SC_TB_TOP__SV
