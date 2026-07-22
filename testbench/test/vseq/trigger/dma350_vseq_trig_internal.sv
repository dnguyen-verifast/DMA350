//==============================================================================
// dma350_vseq_trig_internal.sv
//   INTERNAL TRIGGER CONNECTION (TRM 5.4.4) -- trigger noi CHANNEL -> CHANNEL,
//   khong di ra chan ngoai.
//
//   TRIGTYPE = 2'b11 (INTERNAL). Luc nay CH_*TRIGINCFG.SEL KHONG con la cong
//   TI ma la CHANNEL NGUON phat trigger; va RTL EP mode ve TRIGMODE_CMD bat ke
//   MODE ghi gi (xem dma350_ch_regs.sv: srctrigin_mode = (TYPE==INTERNAL) ?
//   TRIGMODE_CMD : srctrigincfg_q[11:10]).
//
//   Kich ban: CH0 chay xong -> phat trigger-out noi bo -> CH1 (dang cho
//   internal trigger tu CH0) moi bat dau chay.
//==============================================================================
`ifndef DMA350_VSEQ_TRIG_INTERNAL_SV
`define DMA350_VSEQ_TRIG_INTERNAL_SV

class dma350_vseq_trig_internal extends dma350_vseq_trig_base;
  `uvm_object_utils(dma350_vseq_trig_internal)

  int unsigned ch_src = 0;   // channel PHAT trigger (co USETRIGOUT)
  int unsigned ch_dst = 1;   // channel NHAN trigger (USESRCTRIGIN, TYPE=INTERNAL)

  function new(string name = "dma350_vseq_trig_internal");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] st;
    super.body();

    //-------------------------------------------------------------------------
    // CH_dst : cho trigger NOI BO tu CH_src. SEL = channel nguon (khong phai TI)
    //-------------------------------------------------------------------------
    ch          = ch_dst;
    src_addr    = 32'h0002_0000;
    des_addr    = 32'h0002_4000;
    xsize       = 8;
    use_srctrig = 1;
    use_trigout = 0;
    trig_type   = TT_INTERNAL;
    trig_mode   = TM_CMD;       // RTL ep CMD khi INTERNAL - ghi cho ro rang
    trig_sel    = ch_src[7:0];  // <-- channel nguon, KHONG phai cong TI
    cfg_trig_ch();
    enable_ch(ch_dst);

    // CH_dst phai dung cho, chua chay
    check_waiting_trigger("CH_dst cho internal trigger tu CH_src");

    //-------------------------------------------------------------------------
    // CH_src : chay 1 lenh ngan, bat USETRIGOUT de phat trigger noi bo khi xong
    //-------------------------------------------------------------------------
    ch           = ch_src;
    src_addr     = 32'h0001_0000;
    des_addr     = 32'h0001_4000;
    xsize        = 4;
    use_srctrig  = 0;            // CH_src tu chay bang ENABLECMD
    use_trigout  = 1;
    trigout_type = TT_INTERNAL;  // trigger-out noi bo
    trigout_sel  = ch_dst[7:0];  // ban toi channel dich
    cfg_trig_ch();
    enable_ch(ch_src);

    wait_ch_done(ch_src);
    `uvm_info(get_type_name(), $sformatf(
      "CH%0d xong -> da phat internal trigger toi CH%0d", ch_src, ch_dst), UVM_LOW)

    // CH_dst gio moi duoc chay va ket thuc
    wait_ch_done(ch_dst);

    clear_ch_status(ch_src);
    clear_ch_status(ch_dst);
  endtask

endclass : dma350_vseq_trig_internal

`endif // DMA350_VSEQ_TRIG_INTERNAL_SV
