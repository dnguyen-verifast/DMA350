//============================================================================
// dma_trig_in_if.sv
// Trigger INPUT port of the DMA-350 (one per <TI>). The DMA RECEIVES the
// trigger here, so the peripheral VIP is the REQUESTER:
//   VIP drives  : trig_in_req, trig_in_req_type[1:0]
//   VIP samples : trig_in_ack, trig_in_ack_type[1:0]   (driven by the DMAC)
// Directions in the table are from the DMAC's point of view (Table A-7):
//   trig_in_<TI>_req        input   trig_in_<TI>_ack        output
//   trig_in_<TI>_req_type   input   trig_in_<TI>_ack_type   output
//============================================================================
`ifndef DMA_TRIG_IN_IF_SV
`define DMA_TRIG_IN_IF_SV

interface dma_trig_in_if (input logic clk, input logic resetn);

  logic       trig_in_req;
  logic [1:0] trig_in_req_type;
  logic       trig_in_ack;
  logic [1:0] trig_in_ack_type;

  // Requester (peripheral VIP) view: drive req/req_type, sample ack/ack_type.
  clocking req_cb @(posedge clk);
    default input #1step output #1;
    output trig_in_req;
    output trig_in_req_type;
    input  trig_in_ack;
    input  trig_in_ack_type;
  endclocking

  // Passive monitor view.
  clocking mon_cb @(posedge clk);
    default input #1step;
    input trig_in_req, trig_in_req_type, trig_in_ack, trig_in_ack_type;
  endclocking

  modport req (clocking req_cb, input clk, resetn);   // peripheral VIP
  modport mon (clocking mon_cb, input clk, resetn);

  // DUT-facing (DMAC) raw directions, for binding to a real DMA-350.
  modport dut_dmac (
    input  trig_in_req, trig_in_req_type,
    output trig_in_ack, trig_in_ack_type,
    input  clk, resetn
  );

  // --------------------------------------------------------------------
  // 4-phase protocol assertions (TRM 5.4.1).
  // --------------------------------------------------------------------
`ifndef DMA_TRIG_NO_ASSERTS
  // req must be held until ack.
  a_req_hold: assert property (@(posedge clk) disable iff(!resetn)
      (trig_in_req && !trig_in_ack) |=> trig_in_req)
    else $error("[trig_in_if] req dropped before ack (4-phase)");

  // req_type must be stable the whole time req is held.
  a_reqtype_stable: assert property (@(posedge clk) disable iff(!resetn)
      (trig_in_req && !$rose(trig_in_req)) |-> $stable(trig_in_req_type))
    else $error("[trig_in_if] req_type changed while req held");

  // ack must not lead req.
  a_ack_needs_req: assert property (@(posedge clk) disable iff(!resetn)
      $rose(trig_in_ack) |-> trig_in_req)
    else $error("[trig_in_if] ack asserted with no req");

  // No combinational req->ack: ack must not assert in the SAME cycle req rises.
  a_no_comb_ack: assert property (@(posedge clk) disable iff(!resetn)
      $rose(trig_in_req) |-> !trig_in_ack)
    else $error("[trig_in_if] combinational req->ack in same cycle");

  // acktype must never be RESERVED (2'b11) while ack is high.
  a_acktype_not_reserved: assert property (@(posedge clk) disable iff(!resetn)
      $rose(trig_in_ack) |-> (trig_in_ack_type !== 2'b11))
    else $error("[trig_in_if] ack_type == RESERVED (2'b11)");
`endif

endinterface : dma_trig_in_if

`endif // DMA_TRIG_IN_IF_SV
