//============================================================================
// dma_trig_doc.sv  (comment-only; keeps every repo file as .sv)
//============================================================================
// DMA-350 Trigger VIP (UVM) -- peripheral VIP: trig-in requester + trig-out
// responder. Each physical port is its own agent instance, sized to the
// configurable, separate NUM_TRIGGER_IN / NUM_TRIGGER_OUT counts.
//
// KEY ARCHITECTURE POINT (corrected): the peripheral VIP is NOT a pure slave.
// Signal directions (Table A-7) decide who drives what:
//   * Trigger-IN port  (DMA receives): VIP is the REQUESTER
//       VIP drives  trig_in_req, trig_in_req_type[1:0]
//       VIP samples trig_in_ack, trig_in_ack_type[1:0]   (DMAC output)
//     -> the VIP NEVER drives ack_type; that is the DMAC's response.
//   * Trigger-OUT port (DMA emits)   : VIP is the RESPONDER
//       VIP samples trig_out_req                          (DMAC output)
//       VIP drives  trig_out_ack                          (no ack_type)
//
//----------------------------------------------------------------------------
// Folders / packages
//----------------------------------------------------------------------------
//   rtl/        dma_trig_in_if.sv, dma_trig_out_if.sv   (split per direction)
//   common/     dma_trig_common_pkg : types(mode/req/ack), item, cfg
//   trig_in/    dma_trig_in_pkg     : sequencer, driver, monitor, coverage,
//               trig_in/seq/          agent + reqtype/timing/errinj sequences
//   trig_out/   dma_trig_out_pkg    : sequencer, driver, monitor, coverage,
//               trig_out/seq/         agent + ack/stall/swack sequences
//   env/        dma_trig_env_pkg    : scoreboard, vseqr, env (param counts)
//   vseq/       dma_trig_vseq_pkg   : base + smoke/distribute/stall/errinj
//   tb/         dma_trig_dmac_stub.sv (behavioural DMA), tb_top, test_lib
//   import: in/out <- common ; env <- common+in+out ; vseq <- +env ; tb <- all
//
//----------------------------------------------------------------------------
// What the VIP covers (vs the checklist)
//----------------------------------------------------------------------------
// DRIVER (trig-in, dma_trig_in_driver):
//   * valid 4-phase, req_type stable while req held (asserted in the if)
//   * all 4 reqtypes (SINGLE/BLOCK/LAST SINGLE/LAST BLOCK) via sequences
//   * timing variation: pre_delay (req early/late + inter-req gap)
//   * peripheral-as-flow-controller: LAST SINGLE / LAST BLOCK sequences
//   * error injection: mutate req_type while req held (errinj seq) + drive
//     req on an unconnected / pre-enable port (sequence/test orchestrated)
//   * zero-delay ack-wait supported
// DRIVER (trig-out, dma_trig_out_driver):
//   * ack with variable delay incl. VERY long (channel stall before DONE)
//   * SW-ack mode (ack_passive): VIP does not drive hw ack (DUT uses SWTRIGOUTACK)
// MONITOR (both): 4-phase capture, combinational req->ack flag, latency/stall,
//   trig-out hw-ack vs sw-ack path.
// SCOREBOARD (dma_trig_scoreboard, mode = CMD | FLOW):
//   * ack_type never RESERVED (2'b11)
//   * no combinational req->ack
//   * command mode : ack_type OKAY/LAST_OKAY only, DENY illegal (TRM 5.4.1.1)
//   * flow control : DENY only in response to a SINGLE-family request
//   * LAST_OKAY    : legal-value + final-beat consistency note
//   * trig-out     : stall / sw-ack statistics
//   * check_block_count(): hook for "block == TRIGINBLKSIZE AXI transfers /
//     ACK after last response" -- needs an AXI monitor (out of trigger scope).
// COVERAGE:
//   trig_in (A/B/C): reqtype x acktype x latency, mode x acktype
//   trig_out (D)   : stall buckets (incl. very long) x hw/sw ack path
//
// OUT OF SCOPE for a single trigger agent (checklist E/F/G): trigger matrix
// routing, internal channel->channel triggers, pause/stop -- verify at the
// register/sequence layer with channel + AXI agents, not here.
//
//----------------------------------------------------------------------------
// Compile order (filelist)
//----------------------------------------------------------------------------
// --8<-- BEGIN FILELIST --8<--
//   +incdir+common +incdir+trig_in +incdir+trig_out +incdir+env +incdir+vseq +incdir+tb
//   rtl/dma_trig_in_if.sv
//   rtl/dma_trig_out_if.sv
//   common/dma_trig_common_pkg.sv
//   trig_in/dma_trig_in_pkg.sv
//   trig_out/dma_trig_out_pkg.sv
//   env/dma_trig_env_pkg.sv
//   vseq/dma_trig_vseq_pkg.sv
//   tb/dma_trig_dmac_stub.sv
//   tb/dma_trig_tb_top.sv
// --8<-- END FILELIST --8<--
//
//----------------------------------------------------------------------------
// Run (Questa example). Tests: dma_trig_smoke_test, dma_trig_distribute_test,
//   dma_trig_flow_test (+FLOW), dma_trig_stall_test, dma_trig_errinj_test.
//----------------------------------------------------------------------------
//   vlog -sv +incdir+common +incdir+trig_in +incdir+trig_out +incdir+env \
//        +incdir+vseq +incdir+tb \
//        rtl/dma_trig_in_if.sv rtl/dma_trig_out_if.sv \
//        common/dma_trig_common_pkg.sv trig_in/dma_trig_in_pkg.sv \
//        trig_out/dma_trig_out_pkg.sv env/dma_trig_env_pkg.sv \
//        vseq/dma_trig_vseq_pkg.sv tb/dma_trig_dmac_stub.sv tb/dma_trig_tb_top.sv
//   vsim -c dma_trig_tb_top -do "run -all; quit" \
//        +UVM_TESTNAME=dma_trig_smoke_test
//   # flow-control coverage (DENY/LAST_OKAY): add +FLOW and the FLOW test
//   vsim -c dma_trig_tb_top -do "run -all; quit" \
//        +UVM_TESTNAME=dma_trig_flow_test +FLOW
//
// Notes:
//   * +FLOW makes the DMA stub deny SINGLEs / emit LAST_OKAY; pair it ONLY with
//     dma_trig_flow_test (scoreboard mode=FLOW). Do not pass +FLOW to a
//     command-mode test (the scoreboard would correctly flag DENY).
//   * dma_trig_errinj_test intentionally violates req_type stability, so the
//     interface assertion fires -- that is the pass criterion (the checker
//     caught it); demote/expect it in a real regression.
//
//----------------------------------------------------------------------------
// Wrapping a real DMA-350 (remove the stub)
//----------------------------------------------------------------------------
//   * Bind dma_trig_in_if / dma_trig_out_if to the DUT trig_in_* / trig_out_*
//     ports via the dut_dmac modport (one interface per <TI>/<TO>).
//   * Keep all VIP agents ACTIVE; set NUM_TRIGGER_IN/OUT to the build config.
//   * Add an AXI monitor and feed check_block_count() for the block-size and
//     ack-after-last-response checks.
//============================================================================
