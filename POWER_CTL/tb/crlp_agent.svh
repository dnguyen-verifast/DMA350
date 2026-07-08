//==============================================================================
// crlp_agent.svh : Clock / Reset / Low-Power UVM agent
//==============================================================================
`ifndef CRLP_AGENT_SVH
`define CRLP_AGENT_SVH

class crlp_agent extends uvm_agent;
  `uvm_component_utils(crlp_agent)

  crlp_config     cfg;

  crlp_sequencer  sqr;
  crlp_driver     drv;
  crlp_monitor    mon;
  crlp_coverage   cov;

  // Re-export the monitor analysis port for scoreboards.
  uvm_analysis_port #(crlp_seq_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  //--------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Allow the config to be supplied directly or fetched from the db.
    if (cfg == null)
      if (!uvm_config_db#(crlp_config)::get(this, "", "cfg", cfg))
        `uvm_fatal(get_type_name(), "crlp_config not found")

    // Make it visible to children.
    uvm_config_db#(crlp_config)::set(this, "*", "cfg", cfg);

    mon = crlp_monitor::type_id::create("mon", this);

    if (cfg.has_coverage)
      cov = crlp_coverage::type_id::create("cov", this);

    if (cfg.is_active == UVM_ACTIVE) begin
      sqr = crlp_sequencer::type_id::create("sqr", this);
      drv = crlp_driver   ::type_id::create("drv", this);
    end
  endfunction

  //--------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.ap.connect(ap);
    if (cfg.has_coverage)
      mon.ap.connect(cov.analysis_export);
    if (cfg.is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

endclass

`endif // CRLP_AGENT_SVH
