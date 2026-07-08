//==============================================================================
// lpi_pchannel_master_driver.sv
// P-Channel MASTER (controller) driver : drives PSTATE/PREQ, runs the power
// state transition handshake. Master = the side that initiates transitions.
//==============================================================================
class lpi_pchannel_master_driver extends uvm_driver #(lpi_pchannel_item);
  `uvm_component_utils(lpi_pchannel_master_driver)
  lpi_pchannel_cfg cfg;
  bit [`LPI_PSTATE_W-1:0] cur_pstate;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(lpi_pchannel_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal(get_type_name(),"cfg not set")
  endfunction

  task run_phase(uvm_phase phase);
    cfg.vif.preq   = 1'b0;
    cfg.vif.pstate = '0;
    cur_pstate     = '0;
    @(posedge cfg.vif.resetn);
    @(cfg.vif.ctrl_cb);
    forever begin
      lpi_pchannel_item it;
      seq_item_port.get_next_item(it);
      drive_cycle(it);
      seq_item_port.item_done();
    end
  endtask

  task drive_cycle(lpi_pchannel_item it);
    // Ensure P_STABLE before requesting.
    while (!(cfg.vif.ctrl_cb.paccept==1'b0 && cfg.vif.ctrl_cb.pdeny==1'b0))
      @(cfg.vif.ctrl_cb);

    repeat (it.req_delay) @(cfg.vif.ctrl_cb);

    // Present PSTATE first, then assert PREQ (section 3.3.1 margin)
    cfg.vif.ctrl_cb.pstate <= it.pstate;
    repeat (it.setup_delay) @(cfg.vif.ctrl_cb);
    cfg.vif.ctrl_cb.preq <= 1'b1;            // STABLE -> REQUEST

    // Wait accept or deny
    do @(cfg.vif.ctrl_cb);
    while (!(cfg.vif.ctrl_cb.paccept==1'b1 || cfg.vif.ctrl_cb.pdeny==1'b1));

    if (cfg.vif.ctrl_cb.pdeny==1'b1)
      cfg.vif.ctrl_cb.pstate <= cur_pstate;  // DENIED: restore current state
    else
      cur_pstate = it.pstate;                // ACCEPTED: latch new state

    cfg.vif.ctrl_cb.preq <= 1'b0;            // ACCEPT->COMPLETE or DENIED->CONTINUE

    // Wait return to P_STABLE
    do @(cfg.vif.ctrl_cb);
    while (!(cfg.vif.ctrl_cb.paccept==1'b0 && cfg.vif.ctrl_cb.pdeny==1'b0));
  endtask
endclass
