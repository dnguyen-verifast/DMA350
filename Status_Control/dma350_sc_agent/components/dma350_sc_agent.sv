//==============================================================================
// dma350_sc_agent.sv
//------------------------------------------------------------------------------
// Status/Control agent. Bundles the sequencer + driver (active) and monitor
// (always). All four Table A-10 groups are handled by one agent because they
// share the same clock/reset domain and are semantically one interface (4.8).
//
// Active   : driver pumps stop / pause / halt / restart stimulus.
// Passive  : monitor tracks ch_* (and gpo_ch) as the golden reference.
//
// The agent is fully driven by dma350_sc_cfg so it adapts to build-dependent
// signal existence (SECEXT_PRESENT, CH_GPO_MASK, NUM_CHANNELS, GPO_WIDTH).
//==============================================================================
`ifndef DMA350_SC_AGENT__SV
`define DMA350_SC_AGENT__SV

class dma350_sc_agent extends uvm_agent;
  `uvm_component_utils(dma350_sc_agent)

  dma350_sc_cfg        cfg;
  dma350_sc_sequencer  sqr;
  dma350_sc_driver     drv;
  dma350_sc_monitor    mon;

  // Re-export the monitor analysis ports at the agent boundary.
  uvm_analysis_port #(dma350_sc_item) ap;
  uvm_analysis_port #(dma350_sc_item) ap_status;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Allow either an explicitly provided cfg or a default one.
    if (!uvm_config_db#(dma350_sc_cfg)::get(this, "", "cfg", cfg)) begin
      `uvm_info(get_type_name(), "no cfg provided; creating default", UVM_LOW)
      cfg = dma350_sc_cfg::type_id::create("cfg");
    end
    // Make cfg visible to children.
    uvm_config_db#(dma350_sc_cfg)::set(this, "*", "cfg", cfg);

    mon = dma350_sc_monitor::type_id::create("mon", this);

    if (cfg.is_active == UVM_ACTIVE) begin
      sqr = dma350_sc_sequencer::type_id::create("sqr", this);
      drv = dma350_sc_driver   ::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap        = mon.ap;
    ap_status = mon.ap_status;
    if (cfg.is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

endclass : dma350_sc_agent

`endif // DMA350_SC_AGENT__SV
