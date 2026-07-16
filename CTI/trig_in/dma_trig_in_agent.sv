//============================================================================
// dma_trig_in_agent.sv
// Trigger agent cho MOT cap cong <TI>/<TO>: sequencer + driver + monitor
// (+ coverage). Dung interface TONG dma_trig_if (6 signal) va day xuong cho
// driver/monitor.
//   * sequence lai phia trig-in (requester)
//   * phia trig-out do driver AUTO-ACK (DMAC tu phat req) -> khong co agent rieng
//   * monitor chi phat item cho handshake trig-in
//============================================================================
`ifndef DMA_TRIG_IN_AGENT_SV
`define DMA_TRIG_IN_AGENT_SV

class dma_trig_in_agent extends uvm_agent;

  `uvm_component_utils(dma_trig_in_agent)

  dma_trig_cfg            cfg;
  virtual dma_trig_if     vif;

  dma_trig_in_sequencer   sqr;
  dma_trig_in_driver      drv;
  dma_trig_in_monitor     mon;
  dma_trig_in_coverage    cov;

  uvm_analysis_port #(dma_trig_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(dma_trig_cfg)::get(this, "", "cfg", cfg)) begin
      cfg = dma_trig_cfg::type_id::create("cfg");
    end
    if (!uvm_config_db#(virtual dma_trig_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual dma_trig_if 'vif' not set")

    // Hand the typed vif + cfg to children. Driver CAN cfg de biet knob
    // trigout_auto_ack / trigout_ack_delay cho luong auto-ack trig-out.
    uvm_config_db#(virtual dma_trig_if)::set(this, "drv", "vif", vif);
    uvm_config_db#(virtual dma_trig_if)::set(this, "mon", "vif", vif);
    uvm_config_db#(dma_trig_cfg)::set(this, "drv", "cfg", cfg);
    uvm_config_db#(dma_trig_cfg)::set(this, "mon", "cfg", cfg);

    mon = dma_trig_in_monitor::type_id::create("mon", this);
    if (cfg.en_cov) begin
      uvm_config_db#(dma_trig_cfg)::set(this, "cov", "cfg", cfg);
      cov = dma_trig_in_coverage::type_id::create("cov", this);
    end
    if (cfg.is_active == UVM_ACTIVE) begin
      sqr = dma_trig_in_sequencer::type_id::create("sqr", this);
      drv = dma_trig_in_driver::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.ap.connect(ap);
    if (cfg.en_cov) mon.ap.connect(cov.analysis_export);
    if (cfg.is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

endclass : dma_trig_in_agent

`endif // DMA_TRIG_IN_AGENT_SV
