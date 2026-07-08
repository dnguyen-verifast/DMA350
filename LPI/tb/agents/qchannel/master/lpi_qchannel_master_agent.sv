//==============================================================================
// lpi_qchannel_master_agent.sv
// Q-Channel MASTER agent = DEVICE role : device driver (QACCEPTn/QDENY/QACTIVE)
// + sequencer + its OWN master monitor.
//==============================================================================
class lpi_qchannel_master_agent extends uvm_agent;
  `uvm_component_utils(lpi_qchannel_master_agent)
  lpi_qchannel_cfg                   cfg;
  uvm_sequencer #(lpi_qchannel_item) seqr;
  lpi_qchannel_master_driver         drv;
  lpi_qchannel_master_monitor        mon;
  uvm_analysis_port #(lpi_qchannel_item) ap;

  function new(string name, uvm_component parent);
    super.new(name,parent); ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(lpi_qchannel_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal(get_type_name(),"cfg not set")
    uvm_config_db#(lpi_qchannel_cfg)::set(this,"*","cfg",cfg);
    mon = lpi_qchannel_master_monitor::type_id::create("mon", this);
    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = uvm_sequencer#(lpi_qchannel_item)::type_id::create("seqr", this);
      drv  = lpi_qchannel_master_driver::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    mon.ap.connect(ap);
    if (cfg.is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
