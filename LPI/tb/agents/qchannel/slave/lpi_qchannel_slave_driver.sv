//==============================================================================
// lpi_qchannel_slave_driver.sv
// Q-Channel SLAVE = CONTROLLER side (ARM IHI 0068D, Figure 2-1).
//
// The Controller drives QREQn and SAMPLES QACCEPTn/QDENY/QACTIVE. It initiates
// quiescence and follows the state diagram (Figure 2-6) using the device-driven
// signals to know which state has been reached, honouring section 2.1.3:
//   - QREQn 1->0 only from Q_RUN     (QACCEPTn=1 & QDENY=0)
//   - QREQn 0->1 only from Q_STOPPED (both LOW) or Q_DENIED (both HIGH)
// At reset the Controller releases with QREQn HIGH so the interface settles to
// Q_RUN (Q_EXIT -> Q_RUN once the device raises QACCEPTn).
//==============================================================================
class lpi_qchannel_slave_driver extends uvm_driver #(lpi_qchannel_item);
  `uvm_component_utils(lpi_qchannel_slave_driver)
  lpi_qchannel_cfg cfg;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(lpi_qchannel_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal(get_type_name(),"cfg not set")
  endfunction

  task run_phase(uvm_phase phase);
    
    cfg.vif.qreqn = 1'b1;                    // released with QREQn HIGH
    @(posedge cfg.vif.resetn);
    @(cfg.vif.ctrl_cb);
    forever begin
      lpi_qchannel_item it;
      seq_item_port.get_next_item(it);
      drive_cycle(it);
      seq_item_port.item_done();
    end
  endtask

  // One quiescence request/exit cycle, advanced by the observed interface state.
  task drive_cycle(lpi_qchannel_item it);
    // Only request from Q_RUN (QREQn 1->0 rule). Also guards the reset-exit race.
    while (!(cfg.vif.ctrl_cb.qacceptn==1'b1 && cfg.vif.ctrl_cb.qdeny==1'b0))
      @(cfg.vif.ctrl_cb);

    repeat (it.req_delay) @(cfg.vif.ctrl_cb);

    // Q_RUN -> Q_REQUEST
    cfg.vif.ctrl_cb.qreqn <= 1'b0;

    // Wait for the device response : Q_STOPPED (accept) or Q_DENIED (deny).
    do @(cfg.vif.ctrl_cb);
    while (!(cfg.vif.ctrl_cb.qacceptn==1'b0 || cfg.vif.ctrl_cb.qdeny==1'b1));

    repeat (it.hold_delay) @(cfg.vif.ctrl_cb);

    // Q_STOPPED -> Q_EXIT  or  Q_DENIED -> Q_CONTINUE
    cfg.vif.ctrl_cb.qreqn <= 1'b1;

    // Wait for the device to return the interface to Q_RUN.
    do @(cfg.vif.ctrl_cb);
    while (!(cfg.vif.ctrl_cb.qacceptn==1'b1 && cfg.vif.ctrl_cb.qdeny==1'b0));
  endtask
endclass
