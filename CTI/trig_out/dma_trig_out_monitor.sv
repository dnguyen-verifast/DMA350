//============================================================================
// dma_trig_out_monitor.sv
// Observes a trigger-OUT port. Publishes one transaction per req event: the
// req->ack latency (channel stall duration), a combinational-ack flag, and
// whether the request completed via hardware ack or fell without one (SW-ack
// path). req^ before ack^ is enforced by the interface assertion.
//============================================================================
`ifndef DMA_TRIG_OUT_MONITOR_SV
`define DMA_TRIG_OUT_MONITOR_SV

class dma_trig_out_monitor extends uvm_monitor;

  `uvm_component_utils(dma_trig_out_monitor)

  virtual dma_trig_out_if vif;
  int unsigned            port_id;
  uvm_analysis_port #(dma_trig_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    dma_trig_cfg cfg;
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_trig_out_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual dma_trig_out_if 'vif' not set")
    if (uvm_config_db#(dma_trig_cfg)::get(this, "", "cfg", cfg))
      port_id = cfg.port_id;
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      dma_trig_item it;
      int unsigned  cyc;
      bit           comb, hw_acked;
      @(vif.mon_cb iff (vif.resetn && vif.mon_cb.trig_out_req === 1'b1));
      comb = (vif.mon_cb.trig_out_ack === 1'b1);
      it = dma_trig_item::type_id::create("trig_out_hs");
      it.set_transaction_id(port_id);
      it.t_req         = $time;
      it.comb_ack_seen = comb;
      cyc = 0; hw_acked = 0;
      // Wait until ack (hardware) OR req falls (SW-ack path).
      forever begin
        @(vif.mon_cb); cyc++;
        if (!vif.resetn) break;
        if (vif.mon_cb.trig_out_ack === 1'b1) begin hw_acked = 1; break; end
        if (vif.mon_cb.trig_out_req === 1'b0) begin hw_acked = 0; break; end
      end
      if (!vif.resetn) continue;
      it.latency_cycles = cyc;
      it.ack_passive    = ~hw_acked;   // reuse field: 1 => completed without hw ack
      it.t_ack          = $time;
      `uvm_info(get_type_name(),
        $sformatf("trig_out stall=%0d cyc, hw_ack=%0d%s",
                  cyc, hw_acked, comb ? " COMB!" : ""), UVM_HIGH)
      ap.write(it);
      if (hw_acked) begin
        @(vif.mon_cb iff (vif.mon_cb.trig_out_req === 1'b0));
        @(vif.mon_cb iff (vif.mon_cb.trig_out_ack === 1'b0));
      end
    end
  endtask

endclass : dma_trig_out_monitor

`endif // DMA_TRIG_OUT_MONITOR_SV
