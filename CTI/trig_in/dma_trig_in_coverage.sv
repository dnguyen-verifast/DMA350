//============================================================================
// dma_trig_in_coverage.sv
// Functional coverage for trigger-IN handshakes (checklist groups A/B/C):
//   A handshake/encoding : all reqtypes, all (legal) acktypes, latency
//   B command mode       : mode=CMD x acktype (must be OKAY/LAST_OKAY only)
//   C flow-control       : mode=FLOW x reqtype x acktype (BLOCK/LAST, DENY)
//============================================================================
`ifndef DMA_TRIG_IN_COVERAGE_SV
`define DMA_TRIG_IN_COVERAGE_SV

class dma_trig_in_coverage extends uvm_subscriber #(dma_trig_item);

  `uvm_component_utils(dma_trig_in_coverage)

  dma_trig_cfg  cfg;
  dma_trig_item tr;

  covergroup cg_trig_in;
    option.per_instance = 1;

    cp_reqtype : coverpoint tr.observed_reqtype {
      bins single      = {DMA_TRIG_SINGLE};
      bins last_single = {DMA_TRIG_LAST_SINGLE};
      bins block       = {DMA_TRIG_BLOCK};
      bins last_block  = {DMA_TRIG_LAST_BLOCK};
    }
    cp_acktype : coverpoint tr.observed_acktype {
      bins okay      = {DMA_TRIG_OKAY};
      bins last_okay = {DMA_TRIG_LAST_OKAY};
      bins deny      = {DMA_TRIG_DENY};
      illegal_bins reserved = {DMA_TRIG_ACK_RSVD};
    }
    cp_latency : coverpoint tr.latency_cycles {
      bins zero = {0}; bins one = {1}; bins fast = {[2:4]};
      bins med  = {[5:16]}; bins slow = {[17:$]};
    }
    cp_mode : coverpoint cfg.mode {
      bins cmd  = {DMA_TRIG_MODE_CMD};
      bins flow = {DMA_TRIG_MODE_FLOW};
    }
    // A: every reqtype gets an OKAY/LAST_OKAY/DENY response somewhere.
    x_req_ack : cross cp_reqtype, cp_acktype;
    // B/C: mode x acktype (command must never DENY -> that bin should stay 0).
    x_mode_ack : cross cp_mode, cp_acktype;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_trig_in = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_config_db#(dma_trig_cfg)::get(this, "", "cfg", cfg));
    if (cfg == null) cfg = dma_trig_cfg::type_id::create("cov_cfg");
  endfunction

  function void write(dma_trig_item t);
    tr = t;
    cg_trig_in.sample();
  endfunction

endclass : dma_trig_in_coverage

`endif // DMA_TRIG_IN_COVERAGE_SV
