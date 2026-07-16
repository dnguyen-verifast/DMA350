//============================================================================
// dma_trig_out_if.sv
// Trigger OUTPUT port of the DMA-350 (one per <TO>). The DMA EMITS the trigger
// here, so the peripheral VIP is the RESPONDER:
//   VIP samples : trig_out_req   (driven by the DMAC)
//   VIP drives  : trig_out_ack
// There is no ack_type on trig_out (1-bit ack only).
// Directions from the DMAC's point of view (Table A-7):
//   trig_out_<TO>_req  output     trig_out_<TO>_ack  input
//============================================================================
`ifndef DMA_TRIG_OUT_IF_SV
`define DMA_TRIG_OUT_IF_SV

interface dma_trig_out_if (input logic clk, input logic resetn);

  logic trig_out_req;
  logic trig_out_ack;

  // Responder (peripheral VIP) view: sample req, drive ack.
  clocking ack_cb @(posedge clk);
    default input #1step output #1;
    input  trig_out_req;
    output trig_out_ack;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input trig_out_req, trig_out_ack;
  endclocking

  modport ack (clocking ack_cb, input clk, resetn);   // peripheral VIP
  modport mon (clocking mon_cb, input clk, resetn);

  modport dut_dmac (
    output trig_out_req,
    input  trig_out_ack,
    input  clk, resetn
  );

  // --------------------------------------------------------------------
  // 4-phase protocol assertions (TRM 5.4.2/5.4.4).
  // --------------------------------------------------------------------
`ifndef DMA_TRIG_NO_ASSERTS
  a_req_hold: assert property (@(posedge clk) disable iff(!resetn)
      (trig_out_req && !trig_out_ack) |=> trig_out_req)
    else $error("[trig_out_if] req dropped before ack (4-phase)");

  a_ack_needs_req: assert property (@(posedge clk) disable iff(!resetn)
      $rose(trig_out_ack) |-> trig_out_req)
    else $error("[trig_out_if] ack asserted with no req");

  a_no_comb_ack: assert property (@(posedge clk) disable iff(!resetn)
      $rose(trig_out_req) |-> !trig_out_ack)
    else $error("[trig_out_if] combinational req->ack in same cycle");
`endif

endinterface : dma_trig_out_if

`endif // DMA_TRIG_OUT_IF_SV
