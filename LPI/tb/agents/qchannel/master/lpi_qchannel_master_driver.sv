//==============================================================================
// lpi_qchannel_master_driver.sv
// Q-Channel MASTER = DEVICE side (ARM IHI 0068D, Figure 2-1).
//
// The Device drives QACCEPTn, QDENY and QACTIVE and SAMPLES QREQn. It is a
// purely state-based responder: every clock it decodes the interface state
// (Table 2-1) and drives its owned signals to follow the state diagram
// (Figure 2-6), honouring the handshake rules of section 2.1.3:
//   - QACCEPTn 1->0 only when QREQn=0 & QDENY=0     (Q_REQUEST -> Q_STOPPED)
//   - QACCEPTn 0->1 only when QREQn=1 & QDENY=0     (Q_EXIT    -> Q_RUN)
//   - QDENY    0->1 only when QREQn=0 & QACCEPTn=1  (Q_REQUEST -> Q_DENIED)
//   - QDENY    1->0 only when QREQn=1 & QACCEPTn=1  (Q_CONTINUE-> Q_RUN)
// At reset the Device drives QACCEPTn=QDENY=0 (section 2.1.2 Device reset).
//==============================================================================
class lpi_qchannel_master_driver extends uvm_driver #(lpi_qchannel_item);
  `uvm_component_utils(lpi_qchannel_master_driver)
  lpi_qchannel_cfg cfg;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(lpi_qchannel_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal(get_type_name(),"cfg not set")
  endfunction

  task run_phase(uvm_phase phase);
    // Device reset values (Table 2-1 quiescent: all LOW).
    cfg.vif.qacceptn = 1'b0;
    cfg.vif.qdeny    = 1'b0;
    cfg.vif.qactive  = 1'b0;
    @(posedge cfg.vif.resetn);
    @(cfg.vif.dev_cb);
    forever respond();
  endtask

  // State-based response: decode the interface state, then drive the Device
  // outputs to progress to the next legal state.
  task respond();
    q_state_e st = q_decode(cfg.vif.dev_cb.qreqn,
                            cfg.vif.dev_cb.qacceptn,
                            cfg.vif.dev_cb.qdeny);
    case (st)
      // Controller requested exit -> Device acknowledges by raising QACCEPTn.
      Q_EXIT     : begin
                     cfg.vif.dev_cb.qacceptn <= 1'b1;   // Q_EXIT -> Q_RUN
                     @(cfg.vif.dev_cb);
                   end
      // Controller withdrew a denied request -> Device lowers QDENY.
      Q_CONTINUE : begin
                     cfg.vif.dev_cb.qdeny <= 1'b0;      // Q_CONTINUE -> Q_RUN
                     @(cfg.vif.dev_cb);
                   end
      // Controller requested quiescence -> Device accepts or denies per item.
      Q_REQUEST  : begin
                     lpi_qchannel_item it;
                     seq_item_port.get_next_item(it);
                     repeat (it.resp_delay) @(cfg.vif.dev_cb);
                     cfg.vif.dev_cb.qactive <= it.qactive;
                     if (it.deny) cfg.vif.dev_cb.qdeny    <= 1'b1; // -> Q_DENIED
                     else         cfg.vif.dev_cb.qacceptn <= 1'b0; // -> Q_STOPPED
                     @(cfg.vif.dev_cb);
                     seq_item_port.item_done();
                   end
      // Q_RUN / Q_STOPPED / Q_DENIED : steady, nothing for the Device to drive.
      default    : @(cfg.vif.dev_cb);
    endcase
  endtask
endclass
