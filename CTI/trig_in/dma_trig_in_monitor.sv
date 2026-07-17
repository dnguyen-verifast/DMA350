//============================================================================
// dma_trig_in_monitor.sv
// Observes a trigger-IN port and publishes one transaction per completed
// handshake: req_type the VIP drove + ack/ack_type the DMAC returned, the
// req->ack latency, and a combinational-ack flag (ack high the same cycle req
// rose -- a protocol violation).
//============================================================================
`ifndef DMA_TRIG_IN_MONITOR_SV
`define DMA_TRIG_IN_MONITOR_SV

class dma_trig_in_monitor extends uvm_monitor;

  `uvm_component_utils(dma_trig_in_monitor)

  virtual dma_trig_if    vif;
  int unsigned           port_id;
  uvm_analysis_port #(dma_trig_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    dma_trig_cfg cfg;
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_trig_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual dma_trig_if 'vif' not set")
    if (uvm_config_db#(dma_trig_cfg)::get(this, "", "cfg", cfg))
      port_id = cfg.port_id;
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      dma_trig_item it;
      int unsigned  cyc;
      bit           comb;
      // Start of a request.
      @(vif.mon_cb iff (vif.resetn && vif.mon_cb.trig_in_req === 1'b1));
      comb = (vif.mon_cb.trig_in_ack === 1'b1);   // ack in same cycle as req
      it = dma_trig_item::type_id::create("trig_in_hs");
      it.port_id = port_id;
      it.observed_reqtype = dma_trig_reqtype_e'(vif.mon_cb.trig_in_req_type);
      it.reqtype          = it.observed_reqtype;
      it.t_req            = $time;
      it.comb_ack_seen    = comb;
      cyc = 0;
      while (vif.mon_cb.trig_in_ack !== 1'b1) begin
        @(vif.mon_cb); cyc++;
        if (!vif.resetn) break;
      end
      if (!vif.resetn) continue;
      it.observed_acktype = dma_trig_acktype_e'(vif.mon_cb.trig_in_ack_type);
      it.t_ack            = $time;
      it.latency_cycles   = cyc;
      `uvm_info(get_type_name(), it.convert2string(), UVM_HIGH)
      ap.write(it);
      // Wait for full return-to-zero before re-arming.
      @(vif.mon_cb iff (vif.mon_cb.trig_in_req === 1'b0));
      @(vif.mon_cb iff (vif.mon_cb.trig_in_ack === 1'b0));
    end
  endtask

endclass : dma_trig_in_monitor

`endif // DMA_TRIG_IN_MONITOR_SV
