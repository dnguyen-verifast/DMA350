//==============================================================================
// dma350_sc_coverage.sv
//------------------------------------------------------------------------------
// Functional coverage subscriber for the control/status interface. Connect its
// analysis export to the agent's `ap`. Covers the action/domain cross and the
// per-channel status the monitor snapshots.
//==============================================================================
`ifndef DMA350_SC_COVERAGE__SV
`define DMA350_SC_COVERAGE__SV

class dma350_sc_coverage extends uvm_subscriber #(dma350_sc_item);
  `uvm_component_utils(dma350_sc_coverage)

  dma350_sc_cfg  cfg;
  dma350_sc_item tr;

  covergroup cg_action;
    option.per_instance = 1;
    cp_op     : coverpoint tr.op;
    cp_domain : coverpoint tr.domain;
    cp_halted : coverpoint tr.halted_seen;
    // stop/pause seen on each domain
    x_op_dom  : cross cp_op, cp_domain;
  endgroup

  covergroup cg_status;
    option.per_instance = 1;
    cp_any_en   : coverpoint (|tr.ch_enabled) { bins active = {1}; bins idle = {0}; }
    cp_any_err  : coverpoint (|tr.ch_err)     { bins err = {1};    bins ok = {0}; }
    cp_any_stop : coverpoint (|tr.ch_stopped);
    cp_any_pause: coverpoint (|tr.ch_paused);
    // security mix (only meaningful when secext present)
    cp_ns_mix   : coverpoint tr.ch_nonsec[0];
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_action = new();
    cg_status = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_config_db#(dma350_sc_cfg)::get(this, "", "cfg", cfg));
  endfunction

  function void write(dma350_sc_item t);
    tr = t;
    cg_action.sample();
    cg_status.sample();
  endfunction

endclass : dma350_sc_coverage

`endif // DMA350_SC_COVERAGE__SV
