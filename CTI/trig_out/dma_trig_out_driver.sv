//============================================================================
// dma_trig_out_driver.sv
// Trigger-OUT (RESPONDER) driver. The DMAC drives trig_out_req; the peripheral
// VIP drives trig_out_ack to complete the handshake (there is no ack_type).
//
// Capabilities:
//   * HW-ack with configurable delay (item.ack_delay), including a VERY long
//     delay to test the channel stalling before DONE (TRM 5.4.2).
//   * SW-ack mode (item.ack_passive): the VIP does NOT drive the hardware ack,
//     modelling the DMAC being acknowledged via its SWTRIGOUTACK register
//     instead. Use only with a DUT / SW-ack stub (otherwise req stalls).
//   * valid 4-phase: wait req^ -> (delay) -> ack^ -> wait req v -> ack v
//============================================================================
`ifndef DMA_TRIG_OUT_DRIVER_SV
`define DMA_TRIG_OUT_DRIVER_SV

class dma_trig_out_driver extends uvm_driver #(dma_trig_item);

  `uvm_component_utils(dma_trig_out_driver)

  virtual dma_trig_out_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_trig_out_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual dma_trig_out_if 'vif' not set")
  endfunction

  task run_phase(uvm_phase phase);
    drive_idle();
    forever begin
      @(posedge vif.clk);
      if (!vif.resetn) begin drive_idle(); continue; end
      seq_item_port.get_next_item(req);
      respond(req);
      seq_item_port.item_done();
    end
  endtask

  function void drive_idle();
    vif.ack_cb.trig_out_ack <= 1'b0;
  endfunction

  task respond(dma_trig_item it);
    // Wait for the DMAC to raise the output trigger request.
    do @(vif.ack_cb); while (vif.ack_cb.trig_out_req !== 1'b1);
    it.t_req = $time;

    if (it.ack_passive) begin
      // SW-ack mode: never drive the hardware ack; the channel stays stalled
      // on the wire until the DMAC is acknowledged via SWTRIGOUTACK (or until
      // req is withdrawn). Just wait for req to fall.
      `uvm_info(get_type_name(), "SW-ack mode: not driving hardware trig_out_ack",
                UVM_MEDIUM)
      do @(vif.ack_cb); while (vif.ack_cb.trig_out_req !== 1'b0);
      return;
    end

    // HW-ack: optional (possibly long) delay -> the channel stalls until ack.
    repeat (it.ack_delay) @(vif.ack_cb);
    vif.ack_cb.trig_out_ack <= 1'b1;
    it.t_ack = $time;
    do @(vif.ack_cb); while (vif.ack_cb.trig_out_req !== 1'b0);
    vif.ack_cb.trig_out_ack <= 1'b0;
    `uvm_info(get_type_name(),
      $sformatf("trig_out acked after %0d-cycle delay", it.ack_delay), UVM_HIGH)
  endtask

endclass : dma_trig_out_driver

`endif // DMA_TRIG_OUT_DRIVER_SV
