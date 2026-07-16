//============================================================================
// dma_trig_dmac_stub.sv
// Lightweight behavioural DMA-side models so the peripheral VIP can run
// standalone (no real DMA-350). NOT part of the VIP -- they stand in for the
// DUT and are only used by the testbench top to close the handshakes.
//
//   dma_trig_in_dmac  : dung interface TONG dma_trig_if. Drives trig_in_ack /
//                       trig_in_ack_type (the DMAC reply)
//                       command mode (+FLOW absent): OKAY, LAST_OKAY for LAST_*
//                       flow mode    (+FLOW present): OKAY/LAST_OKAY, and DENY a
//                                    fraction of SINGLE requests
//                       Day la cong IN-ONLY -> tie trig_out_req = 0 (luong
//                       auto-ack cua driver se khong kich hoat).
//   dma_trig_out_dmac : dung dma_trig_out_if. Periodically drives trig_out_req
//                       (the DMAC emitting a trigger) and waits for the VIP's ack
//
// reqtype : 00 SINGLE 01 LAST_SINGLE 10 BLOCK 11 LAST_BLOCK
// acktype : 00 OKAY   01 DENY        10 LAST_OKAY
//============================================================================
`timescale 1ns/1ps

module dma_trig_in_dmac (dma_trig_if vif);
  bit flow;
  logic [1:0] rt;
  initial flow = $test$plusargs("FLOW");

  // Cong in-only: phia trig-out cua interface tong khong dung -> giu idle.
  initial vif.trig_out_req = 1'b0;

  initial begin
    vif.trig_in_ack      = 1'b0;
    vif.trig_in_ack_type = 2'b00;
    forever begin
      @(posedge vif.clk);
      if (!vif.resetn) begin
        vif.trig_in_ack <= 1'b0; vif.trig_in_ack_type <= 2'b00; continue;
      end
      if (vif.trig_in_req && !vif.trig_in_ack) begin
        rt = vif.trig_in_req_type;
        repeat ($urandom_range(0,3)) @(posedge vif.clk);  // ack-wait variation
        if (!flow) begin
          // command mode: accept-to-start. OKAY, LAST_OKAY for a LAST_* request.
          vif.trig_in_ack_type <= (rt inside {2'b01,2'b11}) ? 2'b10 : 2'b00;
        end else begin
          // flow control: LAST_* -> LAST_OKAY; SINGLE -> sometimes DENY; else OKAY
          if (rt inside {2'b01,2'b11})            vif.trig_in_ack_type <= 2'b10;
          else if (rt == 2'b00 && ($urandom_range(0,3)==0)) vif.trig_in_ack_type <= 2'b01;
          else                                     vif.trig_in_ack_type <= 2'b00;
        end
        vif.trig_in_ack <= 1'b1;
        @(posedge vif.clk iff !vif.trig_in_req);
        vif.trig_in_ack <= 1'b0;
      end
    end
  end
endmodule : dma_trig_in_dmac

module dma_trig_out_dmac (dma_trig_out_if vif);
  initial begin
    vif.trig_out_req = 1'b0;
    @(posedge vif.clk iff vif.resetn);
    forever begin
      repeat ($urandom_range(20,80)) @(posedge vif.clk);
      if (!vif.resetn) continue;
      vif.trig_out_req <= 1'b1;
      @(posedge vif.clk iff vif.trig_out_ack);   // wait for the VIP's ack
      vif.trig_out_req <= 1'b0;
      @(posedge vif.clk iff !vif.trig_out_ack);
    end
  end
endmodule : dma_trig_out_dmac
