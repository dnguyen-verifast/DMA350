//==============================================================================
// lpi_pchannel_slave_monitor.sv
// P-Channel SLAVE-side monitor : decodes the interface state every clock and
// publishes a transaction on each state change. Belongs to the slave agent.
//==============================================================================
class lpi_pchannel_slave_monitor extends uvm_monitor;
  `uvm_component_utils(lpi_pchannel_slave_monitor)
  lpi_pchannel_cfg cfg;
  uvm_analysis_port #(lpi_pchannel_item) ap;

  function new(string name, uvm_component parent);
    super.new(name,parent); ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(lpi_pchannel_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal(get_type_name(),"cfg not set")
  endfunction

  task run_phase(uvm_phase phase);
    p_state_e prev, curr;
    @(posedge cfg.vif.resetn);
    @(cfg.vif.mon_cb);
    prev = p_decode(1'b1, cfg.vif.mon_cb.preq, cfg.vif.mon_cb.paccept, cfg.vif.mon_cb.pdeny);
    forever begin
      @(cfg.vif.mon_cb);
      curr = p_decode(1'b1, cfg.vif.mon_cb.preq, cfg.vif.mon_cb.paccept, cfg.vif.mon_cb.pdeny);
      if (curr != prev) begin
        lpi_pchannel_item it = lpi_pchannel_item::type_id::create("slv_mon_it");
        it.prev_state = prev;
        it.curr_state = curr;
        it.pstate     = cfg.vif.mon_cb.pstate;
        it.pactive    = cfg.vif.mon_cb.pactive;
        ap.write(it);
        prev = curr;
      end
    end
  endtask
endclass
