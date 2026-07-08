//==============================================================================
// crlp_dut_stub.sv
//   Trivial DMAC-side responder for Q-Channel and P-Channel, used only to
//   exercise the CRLP agent.  Replace with the real DMAC in a full DV env.
//
//   Behaviour:
//     Q-Channel : on qreqn=0 (quiesce req), accept after ACCEPT_DELAY cycles
//                 (qacceptn=0). On qreqn=1 (exit), qacceptn back to 1. Never
//                 denies here (qdeny tied 0). qactive mirrors "running".
//     P-Channel : on preq=1, accept after ACCEPT_DELAY cycles (paccept=1);
//                 on preq=0, drop paccept. Never denies (pdeny tied 0).
//==============================================================================
module crlp_dut_stub #(parameter int ACCEPT_DELAY = 3) (crlp_if bus);

  // ---------------- Q-Channel ----------------
  int q_cnt;
  always_ff @(posedge bus.clk or negedge bus.resetn) begin
    if (!bus.resetn) begin
      bus.clk_qacceptn <= 1'b1;   // Q_RUN
      bus.clk_qdeny    <= 1'b0;
      bus.clk_qactive  <= 1'b1;
      q_cnt            <= 0;
    end
    else begin
      bus.clk_qdeny <= 1'b0;
      if (bus.clk_qreqn == 1'b0) begin
        // quiescence requested
        bus.clk_qactive <= 1'b0;
        if (bus.clk_qacceptn == 1'b1) begin
          if (q_cnt >= ACCEPT_DELAY) begin
            bus.clk_qacceptn <= 1'b0;   // accept
            q_cnt            <= 0;
          end
          else q_cnt <= q_cnt + 1;
        end
      end
      else begin
        // exit requested / running
        bus.clk_qacceptn <= 1'b1;
        bus.clk_qactive  <= 1'b1;
        q_cnt            <= 0;
      end
    end
  end

  // ---------------- P-Channel ----------------
  int p_cnt;
  always_ff @(posedge bus.clk or negedge bus.resetn) begin
    if (!bus.resetn) begin
      bus.paccept <= 1'b0;
      bus.pdeny   <= 1'b0;
      p_cnt       <= 0;
    end
    else begin
      bus.pdeny <= 1'b0;
      if (bus.preq == 1'b1) begin
        if (!bus.paccept) begin
          if (p_cnt >= ACCEPT_DELAY) begin
            bus.paccept <= 1'b1;
            p_cnt       <= 0;
          end
          else p_cnt <= p_cnt + 1;
        end
      end
      else begin
        bus.paccept <= 1'b0;
        p_cnt       <= 0;
      end
    end
  end

endmodule
