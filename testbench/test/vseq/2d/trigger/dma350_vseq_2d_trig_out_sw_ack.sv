//==============================================================================
// dma350_vseq_2d_trig_out_sw_ack.sv
//   GROUP F - TRM 5.4.5.2 'Software trigger output protocol' tren lenh 2D
//   Trigger-out kieu SW: phan mem doc STAT_TRIGOUTACKWAIT roi ghi SWTRIGOUTACK.
//   Ky vong: TRIGOUTACKWAIT set sau dong cuoi; xoa sau khi SW ack; roi moi DONE.
//==============================================================================
`ifndef DMA350_VSEQ_2D_TRIG_OUT_SW_ACK_SV
`define DMA350_VSEQ_2D_TRIG_OUT_SW_ACK_SV

class dma350_vseq_2d_trig_out_sw_ack extends dma350_vseq_2d_trig_base;
  `uvm_object_utils(dma350_vseq_2d_trig_out_sw_ack)

  function new(string name = "dma350_vseq_2d_trig_out_sw_ack");
    super.new(name);
    use_srctrig = 0;
    use_trigout = 1;
    trigout_type = TT_SW;
  endfunction

  virtual task body();
    bit [31:0] st;
    super.body();
    cfg_trig_ch();
    enable_ch(ch);
    wait_ch_bit(ch, S_TRIGOUTACKWAIT, "TRIGOUTACKWAIT sau dong cuoi (2D)");
    apb_read(ch_addr(ch,O_STATUS), st);
    `uvm_info(get_type_name(), $sformatf(
      "CH%0d truoc SW ack: STATUS=0x%08h", ch, st), UVM_LOW)
    send_sw_trigout_ack();
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_trig_out_sw_ack

`endif // DMA350_VSEQ_2D_TRIG_OUT_SW_ACK_SV
