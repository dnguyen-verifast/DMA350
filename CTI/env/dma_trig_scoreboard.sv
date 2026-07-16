//============================================================================
// dma_trig_scoreboard.sv
// Checks trigger semantics observable at the trigger interface.
//
//   in_imp  <- trig-in monitors  : the DMAC's ack/ack_type response
//   out_imp <- trig-out monitors : channel-stall / ack behaviour
//
// Trigger-IN checks (per cfg.mode):
//   * ack_type never RESERVED (2'b11)
//   * no combinational req->ack (same cycle)
//   * command mode  : ack_type must be OKAY/LAST_OKAY, never DENY (TRM 5.4.1.1)
//   * flow control  : DENY only in response to a SINGLE-family request
//                     (DMAC denying a SINGLE while accumulating a BLOCK)
//   * LAST_OKAY     : legal value; flagged if it acks a non-LAST request in
//                     command mode (final-beat marker, informational)
// Trigger-OUT checks:
//   * no combinational req->ack
//   * accumulates channel-stall / SW-ack statistics
//
// NOTE (out of trigger-VIP scope): "block trigger drives exactly TRIGINBLKSIZE
//   AXI transfers, and ACK only after the last response" needs visibility of
//   the AXI side. Wire an AXI monitor into check_block_count() to complete it.
//============================================================================
`ifndef DMA_TRIG_SCOREBOARD_SV
`define DMA_TRIG_SCOREBOARD_SV

`uvm_analysis_imp_decl(_in)
`uvm_analysis_imp_decl(_out)

class dma_trig_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(dma_trig_scoreboard)

  // Mode used to interpret ack_type semantics.
  dma_trig_mode_e mode = DMA_TRIG_MODE_CMD;

  uvm_analysis_imp_in  #(dma_trig_item, dma_trig_scoreboard) in_imp;
  uvm_analysis_imp_out #(dma_trig_item, dma_trig_scoreboard) out_imp;

  int unsigned n_in, n_out, n_okay, n_lastokay, n_deny, n_stall, n_swack, n_err;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    in_imp  = new("in_imp",  this);
    out_imp = new("out_imp", this);
  endfunction

  function void build_phase(uvm_phase phase);
    dma_trig_cfg cfg;
    super.build_phase(phase);
    if (uvm_config_db#(dma_trig_cfg)::get(this, "", "cfg", cfg)) mode = cfg.mode;
  endfunction

  // -------- trig-in handshake (DMAC response) --------
  function void write_in(dma_trig_item t);
    n_in++;

    if (t.comb_ack_seen) begin
      n_err++;
      `uvm_error("SB", $sformatf("trig_in[%0d] combinational req->ack",
                                 t.get_transaction_id()))
    end
    if (t.observed_acktype == DMA_TRIG_ACK_RSVD) begin
      n_err++;
      `uvm_error("SB", $sformatf("trig_in[%0d] ack_type=RESERVED (2'b11)",
                                 t.get_transaction_id()))
    end

    case (t.observed_acktype)
      DMA_TRIG_OKAY      : n_okay++;
      DMA_TRIG_LAST_OKAY : n_lastokay++;
      DMA_TRIG_DENY      : n_deny++;
      default            : ;
    endcase

    if (mode == DMA_TRIG_MODE_CMD) begin
      if (t.observed_acktype == DMA_TRIG_DENY) begin
        n_err++;
        `uvm_error("SB", $sformatf(
          "trig_in[%0d] DENY in COMMAND mode (illegal, TRM 5.4.1.1)",
          t.get_transaction_id()))
      end
      if (t.observed_acktype == DMA_TRIG_LAST_OKAY &&
          !(t.observed_reqtype inside {DMA_TRIG_LAST_SINGLE, DMA_TRIG_LAST_BLOCK}))
        `uvm_info("SB", $sformatf(
          "trig_in[%0d] LAST_OKAY acking non-LAST %s (DMAC flow-controller done)",
          t.get_transaction_id(), t.observed_reqtype.name()), UVM_MEDIUM)
    end else begin
      if (t.observed_acktype == DMA_TRIG_DENY &&
          !(t.observed_reqtype inside {DMA_TRIG_SINGLE, DMA_TRIG_LAST_SINGLE})) begin
        n_err++;
        `uvm_error("SB", $sformatf(
          "trig_in[%0d] DENY in response to %s (DENY only valid for SINGLE)",
          t.get_transaction_id(), t.observed_reqtype.name()))
      end
    end

    `uvm_info("SB", $sformatf("trig_in[%0d] %s", t.get_transaction_id(),
                              t.convert2string()), UVM_HIGH)
  endfunction

  // -------- trig-out handshake (channel stall / ack) --------
  function void write_out(dma_trig_item t);
    n_out++;
    if (t.comb_ack_seen) begin
      n_err++;
      `uvm_error("SB", $sformatf("trig_out[%0d] combinational req->ack",
                                 t.get_transaction_id()))
    end
    if (t.ack_passive)           n_swack++;   // completed without hardware ack
    if (t.latency_cycles >= 128) n_stall++;   // long channel stall before DONE
    `uvm_info("SB", $sformatf("trig_out[%0d] stall=%0d hw_ack=%0d",
              t.get_transaction_id(), t.latency_cycles, !t.ack_passive), UVM_HIGH)
  endfunction

  // Hook for AXI-aware block-count checking (needs an AXI monitor).
  virtual function void check_block_count(int unsigned port, int unsigned n_axi,
                                          int unsigned trig_blk_size);
    if (n_axi != trig_blk_size) begin
      n_err++;
      `uvm_error("SB", $sformatf(
        "trig_in[%0d] block drove %0d AXI transfers, expected TRIGINBLKSIZE=%0d",
        port, n_axi, trig_blk_size))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SB", $sformatf({"\n==== Trigger scoreboard (mode=%s) ====\n",
                 "  trig-in handshakes : %0d (okay=%0d last_okay=%0d deny=%0d)\n",
                 "  trig-out handshakes: %0d (long-stall=%0d sw-ack=%0d)\n",
                 "  errors             : %0d"},
                 mode.name(), n_in, n_okay, n_lastokay, n_deny,
                 n_out, n_stall, n_swack, n_err), UVM_LOW)
    if (n_err != 0) `uvm_error("SB", $sformatf("%0d trigger semantic error(s)", n_err))
  endfunction

endclass : dma_trig_scoreboard

`endif // DMA_TRIG_SCOREBOARD_SV
