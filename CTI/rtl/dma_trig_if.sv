//============================================================================
// dma_trig_if.sv
// Interface TONG cho MOT cap cong trigger cua DMA-350 (Table A-7): gom CA 6
// signal cua trig-in <TI> va trig-out <TO> tren cung 1 interface.
//
// Huong tin hieu theo goc nhin DMAC (DUT):
//   trig_in_req       input   <- VIP (peripheral) la REQUESTER
//   trig_in_req_type  input   <- VIP
//   trig_in_ack       output  -> DMAC tra loi
//   trig_in_ack_type  output  -> DMAC tra loi
//   trig_out_req      output  -> DMAC phat trigger ra
//   trig_out_ack      input   <- VIP ack de DMAC HA req xuong
//
// Trong testbench DMA-350, trig-out do DMA TU PHAT nen ta khong can agent rieng
// de tao stimulus; chi can ack lai cho DMAC ha req (4-phase hoan tat). Viec ack
// nay do dma_trig_in_driver lam trong luong auto-ack chay nen.
//============================================================================
`ifndef DMA_TRIG_IF_SV
`define DMA_TRIG_IF_SV

interface dma_trig_if (input logic clk, input logic resetn);

  // ---- trig-in (<TI>) ----
  logic       trig_in_req;
  logic [1:0] trig_in_req_type;
  logic       trig_in_ack;
  logic [1:0] trig_in_ack_type;
  // ---- trig-out (<TO>) ----
  logic       trig_out_req;
  logic       trig_out_ack;

  // Driver (peripheral VIP) view:
  //   drive : trig_in_req/req_type (requester) + trig_out_ack (responder)
  //   sample: trig_in_ack/ack_type + trig_out_req
  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output trig_in_req;
    output trig_in_req_type;
    output trig_out_ack;
    input  trig_in_ack;
    input  trig_in_ack_type;
    input  trig_out_req;
  endclocking

  // Passive monitor view: sample tat ca.
  clocking mon_cb @(posedge clk);
    default input #1step;
    input trig_in_req, trig_in_req_type, trig_in_ack, trig_in_ack_type;
    input trig_out_req, trig_out_ack;
  endclocking

  modport drv (clocking drv_cb, input clk, resetn);   // peripheral VIP
  modport mon (clocking mon_cb, input clk, resetn);

  // DUT-facing (DMAC) raw directions.
  modport dut_dmac (
    input  trig_in_req, trig_in_req_type,
    output trig_in_ack, trig_in_ack_type,
    output trig_out_req,
    input  trig_out_ack,
    input  clk, resetn
  );

  // --------------------------------------------------------------------
  // 4-phase protocol assertions (TRM 5.4.1 / 5.4.2 / 5.4.4).
  // --------------------------------------------------------------------
`ifndef DMA_TRIG_NO_ASSERTS
  // ---- trig-in ----
  a_in_req_hold: assert property (@(posedge clk) disable iff(!resetn)
      (trig_in_req && !trig_in_ack) |=> trig_in_req)
    else $error("[dma_trig_if] trig_in_req dropped before ack (4-phase)");

  a_in_reqtype_stable: assert property (@(posedge clk) disable iff(!resetn)
      (trig_in_req && !$rose(trig_in_req)) |-> $stable(trig_in_req_type))
    else $error("[dma_trig_if] trig_in_req_type changed while req held");

  a_in_ack_needs_req: assert property (@(posedge clk) disable iff(!resetn)
      $rose(trig_in_ack) |-> trig_in_req)
    else $error("[dma_trig_if] trig_in_ack asserted with no req");

  a_in_no_comb_ack: assert property (@(posedge clk) disable iff(!resetn)
      $rose(trig_in_req) |-> !trig_in_ack)
    else $error("[dma_trig_if] combinational trig_in req->ack in same cycle");

  a_in_acktype_not_reserved: assert property (@(posedge clk) disable iff(!resetn)
      $rose(trig_in_ack) |-> (trig_in_ack_type !== 2'b11))
    else $error("[dma_trig_if] trig_in_ack_type == RESERVED (2'b11)");

  // ---- trig-out ----
  a_out_req_hold: assert property (@(posedge clk) disable iff(!resetn)
      (trig_out_req && !trig_out_ack) |=> trig_out_req)
    else $error("[dma_trig_if] trig_out_req dropped before ack (4-phase)");

  a_out_ack_needs_req: assert property (@(posedge clk) disable iff(!resetn)
      $rose(trig_out_ack) |-> trig_out_req)
    else $error("[dma_trig_if] trig_out_ack asserted with no req");

  a_out_no_comb_ack: assert property (@(posedge clk) disable iff(!resetn)
      $rose(trig_out_req) |-> !trig_out_ack)
    else $error("[dma_trig_if] combinational trig_out req->ack in same cycle");
`endif

endinterface : dma_trig_if

`endif // DMA_TRIG_IF_SV
