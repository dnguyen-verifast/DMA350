//==============================================================================
// dma350_vseq_trig_srcflow_descmd.sv
//   TRM Figure 5-17 : "Flow control mode trigger for SOURCE and COMMAND for
//                      DESTINATION"
//
//   SOURCE      : TRIGMODE = FLOW_CONTROL (TM_FLOW_DMA, MODE[1]=1)
//                 -> moi trigger tren cong TI0 cap phep them du lieu DOC
//   DESTINATION : TRIGMODE = COMMAND      (TM_CMD)
//                 -> chi 1 trigger tren cong TI1, dung de KHOI DONG lenh ghi
//
//   Hai phia dung HAI CONG TI KHAC NHAU (TI0 cho src, TI1 cho des) vi moi cong
//   trigger la mot giao dien vat ly rieng.
//
//   Trinh tu:
//     1. enable channel -> channel cho ca hai trigger
//     2. ban 1 COMMAND trigger cho DES (TI1)  -> mo duong ghi
//     3. ban chuoi FLOW-CONTROL trigger cho SRC (TI0): SINGLE... roi
//        LAST_SINGLE de bao het du lieu
//     4. channel hoan tat
//==============================================================================
`ifndef DMA350_VSEQ_TRIG_SRCFLOW_DESCMD_SV
`define DMA350_VSEQ_TRIG_SRCFLOW_DESCMD_SV

class dma350_vseq_trig_srcflow_descmd extends dma350_vseq_trig_base;
  `uvm_object_utils(dma350_vseq_trig_srcflow_descmd)

  // So SINGLE truoc LAST_SINGLE tren SRC. LAST_SINGLE cung mang 1 credit, nen
  // tong credit = n_src_single + 1 PHAI bang xsize. Dat trong body() theo xsize
  // de khong lech khi doi xsize (xem gan cuoi new()).
  int unsigned n_src_single;

  function new(string name = "dma350_vseq_trig_srcflow_descmd");
    super.new(name);
    ch          = 0;
    src_addr    = 32'h0006_0000;
    des_addr    = 32'h0006_4000;
    xsize       = 8;

    // ---- SOURCE : FLOW CONTROL, cong TI0 ----
    use_srctrig = 1;
    trig_type   = TT_HW;
    trig_mode   = TM_FLOW_DMA;     // <-- flow control cho SOURCE
    trig_sel    = 0;               // cong TI0
    blksize     = 3;

    // ---- DESTINATION : COMMAND, cong TI1 ----
    use_destrig      = 1;
    separate_des_cfg = 1;          // <-- des cau hinh RIENG, khac src
    des_trig_type    = TT_HW;
    des_trig_mode    = TM_CMD;     // <-- command cho DESTINATION
    des_trig_sel     = 1;          // cong TI1
    des_blksize      = 3;

    // SRC flow-control: tong credit phai DUNG bang xsize.
    // xsize=8 -> 7 SINGLE + 1 LAST_SINGLE = 8 credit.
    // (truoc day dat cung 8 -> thanh 9 credit, trigger cuoi khong ai tieu thu)
    n_src_single = xsize - 1;
  endfunction

  virtual task body();
    super.body();

    cfg_trig_ch();
    log_src_des_mode();            // in ro: SRC=FLOW_CONTROL, DES=COMMAND
    enable_ch(ch);

    check_waiting_trigger("cho trigger (src flow-control + des command)");

    // (2) DES : 1 COMMAND trigger tren TI1 -> khoi dong phia ghi
    fork
      begin : T1
        `uvm_info(get_type_name(),
          "DES (COMMAND mode): gui 1 trigger khoi dong tren TI1", UVM_LOW)
        send_des_trig(RQ_SINGLE, 1);
      end
      begin : T2
        // (3) SRC : chuoi FLOW-CONTROL trigger tren TI0
        `uvm_info(get_type_name(),
          "SRC (FLOW CONTROL mode): gui chuoi SINGLE roi LAST_SINGLE tren TI0", UVM_LOW)
        send_src_trig(RQ_SINGLE,      n_src_single);
        send_src_trig(RQ_LAST_SINGLE, 1);
      end
    join

    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_trig_srcflow_descmd

`endif // DMA350_VSEQ_TRIG_SRCFLOW_DESCMD_SV
