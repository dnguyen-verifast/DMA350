//============================================================================
// dma_trig_in_driver.sv
// Driver cua MOT cap cong trigger, dung interface TONG dma_trig_if (6 signal).
// Chay 2 luong song song:
//
//  (1) REQUESTER - trig-in : lay item tu sequencer va lai 4-phase
//        req^ -> cho ack^ -> req v -> cho ack v
//      * req_type giu on dinh suot thoi gian req HIGH
//      * pre_delay: bien thien thoi diem phat req / khoang cach giua cac req
//      * error injection: doi req_type khi req dang giu (stimulus bat hop le)
//      * ho tro ack tre 0 chu ky
//
//  (2) RESPONDER - trig-out (AUTO-ACK, chay nen, KHONG can sequence):
//      trig-out do DMAC TU PHAT nen ta khong tao stimulus; chi ack lai de DMAC
//      HA trig_out_req xuong (neu khong ack, channel se treo cho ack - TRM 5.4.2).
//      Dieu khien bang cfg.trigout_auto_ack / cfg.trigout_ack_delay.
//============================================================================
`ifndef DMA_TRIG_IN_DRIVER_SV
`define DMA_TRIG_IN_DRIVER_SV

class dma_trig_in_driver extends uvm_driver #(dma_trig_item);

  `uvm_component_utils(dma_trig_in_driver)

  virtual dma_trig_if vif;
  dma_trig_cfg        cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_trig_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual dma_trig_if 'vif' not set")
    // cfg khong bat buoc: thieu thi dung mac dinh (auto-ack bat, delay 0)
    if (!uvm_config_db#(dma_trig_cfg)::get(this, "", "cfg", cfg))
      cfg = dma_trig_cfg::type_id::create("cfg");
  endfunction

  task run_phase(uvm_phase phase);
    drive_idle();
    fork
      drive_trig_in();      // (1) requester : theo sequence
      auto_ack_trig_out();  // (2) responder : tu dong, chay nen
    join_none
  endtask

  function void drive_idle();
    vif.drv_cb.trig_in_req      <= 1'b0;
    vif.drv_cb.trig_in_req_type <= '0;
    vif.drv_cb.trig_out_ack     <= 1'b0;
  endfunction

  //--------------------------------------------------------------------------
  // (1) trig-in : REQUESTER
  //--------------------------------------------------------------------------
  task drive_trig_in();
    forever begin
      @(posedge vif.clk);
      if (!vif.resetn) begin
        vif.drv_cb.trig_in_req      <= 1'b0;
        vif.drv_cb.trig_in_req_type <= '0;
        continue;
      end
      seq_item_port.get_next_item(req);
      drive_req(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_req(dma_trig_item it);
    // Idle gap / early-late control.
    repeat (it.pre_delay) @(vif.drv_cb);

    it.t_req = $time;
    vif.drv_cb.trig_in_req      <= 1'b1;
    vif.drv_cb.trig_in_req_type <= it.reqtype;

    // Optional illegal injection: change req_type while req held (1-2 cycles in).
    if (it.err_reqtype_change) begin
      @(vif.drv_cb);
      if (vif.drv_cb.trig_in_ack !== 1'b1) begin
        vif.drv_cb.trig_in_req_type <= it.err_reqtype_alt;
        `uvm_warning(get_type_name(),
          $sformatf("ERR-INJECT: req_type %s->%s while req held",
                    it.reqtype.name(), it.err_reqtype_alt.name()))
      end
    end

    // Wait for ack (zero-delay possible: ack may already be high next sample).
    do @(vif.drv_cb); while (vif.drv_cb.trig_in_ack !== 1'b1);
    it.t_ack            = $time;
    it.observed_acktype = dma_trig_acktype_e'(vif.drv_cb.trig_in_ack_type);

    // Return-to-zero.
    vif.drv_cb.trig_in_req      <= 1'b0;
    vif.drv_cb.trig_in_req_type <= '0;
    do @(vif.drv_cb); while (vif.drv_cb.trig_in_ack !== 1'b0);

    `uvm_info(get_type_name(),
      $sformatf("req=%s -> ack=%s", it.reqtype.name(), it.observed_acktype.name()),
      UVM_HIGH)
  endtask

  //--------------------------------------------------------------------------
  // (2) trig-out : RESPONDER auto-ack (de DMAC ha trig_out_req xuong)
  //--------------------------------------------------------------------------
  task auto_ack_trig_out();
    forever begin
      @(vif.drv_cb);
      if (!vif.resetn) begin
        vif.drv_cb.trig_out_ack <= 1'b0;
        continue;
      end
      // Tat auto-ack => de DMAC treo cho SWTRIGOUTACK (SW-ack / test stall).
      if (!cfg.trigout_auto_ack)        continue;
      if (vif.drv_cb.trig_out_req !== 1'b1) continue;

      // Tre truoc khi ack (0 = ack ngay chu ky ke tiep). Assertion a_out_no_comb_ack
      // van an toan vi output skew day ack sang chu ky sau.
      repeat (cfg.trigout_ack_delay) @(vif.drv_cb);
      vif.drv_cb.trig_out_ack <= 1'b1;

      // Giu ack den khi DMAC ha req (4-phase), roi tra ack ve 0.
      do @(vif.drv_cb); while (vif.drv_cb.trig_out_req !== 1'b0);
      vif.drv_cb.trig_out_ack <= 1'b0;

      `uvm_info(get_type_name(), $sformatf(
        "trig_out auto-acked (delay=%0d) -> DMAC ha req", cfg.trigout_ack_delay), UVM_HIGH)
    end
  endtask

endclass : dma_trig_in_driver

`endif // DMA_TRIG_IN_DRIVER_SV
