//==============================================================================
// lpi_qchannel_master_monitor.sv
// Q-Channel MASTER-side monitor : decodes the interface state every clock and
// publishes a transaction on each state change. Lives in / belongs to the
// master agent.
//==============================================================================
class lpi_qchannel_master_monitor extends uvm_monitor;
  `uvm_component_utils(lpi_qchannel_master_monitor)
  lpi_qchannel_cfg cfg;
  uvm_analysis_port #(lpi_qchannel_item) ap;

  function new(string name, uvm_component parent);
    super.new(name,parent); ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(lpi_qchannel_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal(get_type_name(),"cfg not set")
  endfunction

  task run_phase(uvm_phase phase);
    q_state_e prev, curr;
    @(posedge cfg.vif.resetn);
    @(cfg.vif.mon_cb);
    prev = q_decode(cfg.vif.mon_cb.qreqn, cfg.vif.mon_cb.qacceptn, cfg.vif.mon_cb.qdeny);
    forever begin
      @(cfg.vif.mon_cb);
      curr = q_decode(cfg.vif.mon_cb.qreqn, cfg.vif.mon_cb.qacceptn, cfg.vif.mon_cb.qdeny);
      if (curr != prev) begin
        lpi_qchannel_item it = lpi_qchannel_item::type_id::create("mas_mon_it");
        it.prev_state = prev;
        it.curr_state = curr;
        it.qactive    = cfg.vif.mon_cb.qactive;
        ap.write(it);
        prev = curr;
      end
    end
  endtask
endclass
