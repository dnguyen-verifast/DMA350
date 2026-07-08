//==============================================================================
// lpi_pchannel_slave_agent.sv
// P-Channel SLAVE agent : slave driver + sequencer + its OWN slave monitor.
//==============================================================================
class lpi_pchannel_slave_agent extends uvm_agent;
  `uvm_component_utils(lpi_pchannel_slave_agent)
  lpi_pchannel_cfg                   cfg;
  uvm_sequencer #(lpi_pchannel_item) seqr;
  lpi_pchannel_slave_driver          drv;
  lpi_pchannel_slave_monitor         mon;
  uvm_analysis_port #(lpi_pchannel_item) ap;

  function new(string name, uvm_component parent);
    super.new(name,parent); ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(lpi_pchannel_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal(get_type_name(),"cfg not set")
    uvm_config_db#(lpi_pchannel_cfg)::set(this,"*","cfg",cfg);
    mon = lpi_pchannel_slave_monitor::type_id::create("mon", this);
    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = uvm_sequencer#(lpi_pchannel_item)::type_id::create("seqr", this);
      drv  = lpi_pchannel_slave_driver::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    mon.ap.connect(ap);
    if (cfg.is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
