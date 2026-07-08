//------------------------------------------------------------------------------
// boot_agent.sv
//
// UVM agent wrapping the boot driver, sequencer, monitor and coverage.
//------------------------------------------------------------------------------
`ifndef BOOT_AGENT_SV
`define BOOT_AGENT_SV

typedef uvm_sequencer #(boot_seq_item) boot_sequencer;

class boot_agent extends uvm_agent;
  `uvm_component_utils(boot_agent)

  boot_agent_cfg  cfg;

  boot_sequencer  sqr;
  boot_driver     drv;
  boot_monitor    mon;
  boot_coverage   cov;

  // Re-export the monitor's analysis port for convenience.
  uvm_analysis_port #(boot_seq_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boot_agent_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "boot_agent_cfg not set for agent")

    // Push cfg down to children.
    uvm_config_db#(boot_agent_cfg)::set(this, "*", "cfg", cfg);

    mon = boot_monitor::type_id::create("mon", this);

    if (cfg.is_active == UVM_ACTIVE) begin
      sqr = boot_sequencer::type_id::create("sqr", this);
      drv = boot_driver  ::type_id::create("drv", this);
    end

    if (cfg.enable_coverage)
      cov = boot_coverage::type_id::create("cov", this);

    ap = new("ap", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.ap.connect(ap);
    if (cfg.enable_coverage)
      mon.ap.connect(cov.analysis_export);
    if (cfg.is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

endclass : boot_agent

`endif // BOOT_AGENT_SV
