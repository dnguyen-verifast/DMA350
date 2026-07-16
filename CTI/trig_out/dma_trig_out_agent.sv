//============================================================================
// dma_trig_out_agent.sv
// Trigger-OUT (responder) agent: sequencer + driver + monitor (+ coverage).
//============================================================================
`ifndef DMA_TRIG_OUT_AGENT_SV
`define DMA_TRIG_OUT_AGENT_SV

class dma_trig_out_agent extends uvm_agent;

  `uvm_component_utils(dma_trig_out_agent)

  dma_trig_cfg             cfg;
  virtual dma_trig_out_if  vif;

  dma_trig_out_sequencer   sqr;
  dma_trig_out_driver      drv;
  dma_trig_out_monitor     mon;
  dma_trig_out_coverage    cov;

  uvm_analysis_port #(dma_trig_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(dma_trig_cfg)::get(this, "", "cfg", cfg))
      cfg = dma_trig_cfg::type_id::create("cfg");
    if (!uvm_config_db#(virtual dma_trig_out_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual dma_trig_out_if 'vif' not set")

    uvm_config_db#(virtual dma_trig_out_if)::set(this, "drv", "vif", vif);
    uvm_config_db#(virtual dma_trig_out_if)::set(this, "mon", "vif", vif);
    uvm_config_db#(dma_trig_cfg)::set(this, "mon", "cfg", cfg);

    mon = dma_trig_out_monitor::type_id::create("mon", this);
    if (cfg.en_cov)
      cov = dma_trig_out_coverage::type_id::create("cov", this);
    if (cfg.is_active == UVM_ACTIVE) begin
      sqr = dma_trig_out_sequencer::type_id::create("sqr", this);
      drv = dma_trig_out_driver::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.ap.connect(ap);
    if (cfg.en_cov) mon.ap.connect(cov.analysis_export);
    if (cfg.is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

endclass : dma_trig_out_agent

`endif // DMA_TRIG_OUT_AGENT_SV
