//------------------------------------------------------------------------------
// dma_irq_agent.sv
// Agent passive: chi instantiate monitor. Khong co driver/sequencer vi chi quan sat.
//------------------------------------------------------------------------------
class dma_irq_agent #(
  parameter int NUM_CHANNELS   = 8,
  parameter bit SECEXT_PRESENT = 1
) extends uvm_agent;

  typedef dma_irq_monitor#(NUM_CHANNELS, SECEXT_PRESENT) mon_t;
  typedef dma_irq_config #(NUM_CHANNELS, SECEXT_PRESENT) cfg_t;
  typedef dma_irq_item   #(NUM_CHANNELS)                 item_t;

  mon_t monitor;
  cfg_t cfg;

  // Re-export analysis port cua monitor de env ket noi de dang
  uvm_analysis_port #(item_t) ap;

  `uvm_component_utils(dma_irq_agent#(NUM_CHANNELS, SECEXT_PRESENT))

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Lay config; neu env chua set thi bao loi
    if (!uvm_config_db#(cfg_t)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "Khong lay duoc dma_irq_config tu config_db")

    // Ep agent luon passive (chi monitor)
    cfg.is_active = UVM_PASSIVE;

    // Truyen config xuong monitor
    uvm_config_db#(cfg_t)::set(this, "monitor", "cfg", cfg);

    monitor = mon_t::type_id::create("monitor", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = monitor.ap;   // xuat analysis port ra ngoai
  endfunction

endclass : dma_irq_agent
