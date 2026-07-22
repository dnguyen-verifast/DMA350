//==============================================================================
// dma350_vseq_trig_sw_trigout_ack.sv
//   SOFTWARE ACK cho TRIGGER-OUT (TRM 5.4.2 / 5.4.3).
//
//   Khi channel co USETRIGOUT, ket thuc lenh no phat trig_out_req va TREO cho
//   ack. Binh thuong peripheral ack bang chan trig_out_ack (driver cua VIP
//   trigger tu auto-ack). Test nay TAT auto-ack de chung minh:
//     * khong ai ack  -> channel treo o TRIGOUTACKWAIT (bit 26), chua DONE
//     * SW ghi CH_CMD.SWTRIGOUTACK (bit24) -> channel moi hoan tat
//
//   Tat auto-ack: dat cfg.trigout_auto_ack = 0 cho agent trigger dang phuc vu
//   cong TO nay (lay cfg qua config_db do base test da set).
//==============================================================================
`ifndef DMA350_VSEQ_TRIG_SW_TRIGOUT_ACK_SV
`define DMA350_VSEQ_TRIG_SW_TRIGOUT_ACK_SV

class dma350_vseq_trig_sw_trigout_ack extends dma350_vseq_trig_base;
  `uvm_object_utils(dma350_vseq_trig_sw_trigout_ack)

  function new(string name = "dma350_vseq_trig_sw_trigout_ack");
    super.new(name);
    ch           = 0;
    src_addr     = 32'h0005_0000;
    des_addr     = 32'h0005_4000;
    xsize        = 4;
    use_srctrig  = 0;            // tu chay bang ENABLECMD
    use_trigout  = 1;            // <-- phat trigger-out khi xong
    trigout_type = TT_HW;        // ra chan trig_out_* cua cong TO0
    trigout_sel  = 0;
  endfunction

  virtual task body();
    bit [31:0] st;
    dma_trig_cfg tcfg;
    super.body();

    // ---- TAT auto-ack tren cong TO0 de channel phai cho SW ack ----
    if (uvm_config_db#(dma_trig_cfg)::get(
            null, "uvm_test_top.dma350_env_h.trig_agt_t0", "cfg", tcfg)) begin
      tcfg.trigout_auto_ack = 0;
      `uvm_info(get_type_name(),
        "da TAT trigout_auto_ack tren TI/TO0 -> channel se cho SWTRIGOUTACK", UVM_LOW)
    end
    else begin
      `uvm_warning(get_type_name(),
        "khong lay duoc dma_trig_cfg cua trig_agt_t0 : VIP se van auto-ack, test mat y nghia")
    end

    cfg_trig_ch();
    enable_ch(ch);

    // Transfer chay xong phan du lieu roi TREO o TRIGOUTACKWAIT vi khong ai ack.
    // Poll vai lan cho chac chan la dang treo (chua DONE).
    repeat (30) apb_read(ch_addr(ch,O_STATUS), st);
    `uvm_info(get_type_name(), $sformatf(
      "CH%0d STATUS=0x%08h (DONE=%0b TRIGOUTACKWAIT=%0b)",
      ch, st, st[S_DONE], st[S_TRIGOUTACKWAIT]), UVM_LOW)
    if (st[S_DONE])
      `uvm_error(get_type_name(), $sformatf(
        "CH%0d DONE khi CHUA co ack cho trig_out -> channel khong cho ack", ch))

    // ---- SW ack -> channel moi hoan tat ----
    send_sw_trigout_ack();
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_trig_sw_trigout_ack

`endif // DMA350_VSEQ_TRIG_SW_TRIGOUT_ACK_SV
