//==============================================================================
// dma350_vseq_trig_sw_des.sv
//   SOFTWARE TRIGGER (TRM 5.4.3) -- DESTINATION trigger phat bang phan mem.
//
//   CH_CTRL[26] USEDESTRIGIN + CH_DESTRIGINCFG.TYPE = SW.
//   SW ghi CH_CMD.DESSWTRIGINREQ (bit20) + DESSWTRIGINTYPE ([22:21]).
//
//   Khac voi src-trigger: trigger dich cap phep GHI (phia destination), dung
//   khi peripheral dich moi la ben quyet dinh nhip nhan du lieu.
//   Trang thai cho tuong ung la CH_STATUS.DESTRIGINWAIT (bit 25).
//==============================================================================
`ifndef DMA350_VSEQ_TRIG_SW_DES_SV
`define DMA350_VSEQ_TRIG_SW_DES_SV

class dma350_vseq_trig_sw_des extends dma350_vseq_trig_base;
  `uvm_object_utils(dma350_vseq_trig_sw_des)

  int unsigned n_single = 8;

  function new(string name = "dma350_vseq_trig_sw_des");
    super.new(name);
    ch          = 0;
    src_addr    = 32'h0004_0000;
    des_addr    = 32'h0004_4000;
    xsize       = 8;
    use_srctrig = 0;
    use_destrig = 1;            // <-- trigger phia DICH
    trig_type   = TT_SW;
    trig_mode   = TM_CMD;
  endfunction

  virtual task body();
    super.body();

    cfg_trig_ch();
    enable_ch(ch);

    check_waiting_trigger("cho SW des-trigger (DESTRIGINWAIT)");

    repeat (n_single) send_sw_destrig(RQ_SINGLE);
    send_sw_destrig(RQ_LAST_SINGLE);

    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_trig_sw_des

`endif // DMA350_VSEQ_TRIG_SW_DES_SV
