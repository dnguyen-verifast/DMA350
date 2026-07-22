//==============================================================================
// dma350_vseq_trig_srccmd_desblock.sv
//   TRM Figure 5-18 : "COMMAND trigger for SOURCE and BLOCK for DESTINATION"
//
//   SOURCE      : TRIGMODE = COMMAND (TM_CMD)
//                 -> chi 1 trigger tren cong TI0, dung de KHOI DONG lenh doc
//   DESTINATION : TRIGMODE = FLOW_CONTROL (TM_FLOW_DMA) voi reqtype = BLOCK
//                 -> moi trigger tren cong TI1 cap phep GHI mot BLOCK
//                    (BLKSIZE+1 item), ket bang LAST_BLOCK
//
//   Khac Fig 5-17 o cho: phia flow-control la DESTINATION (khong phai source),
//   va don vi cap phep la BLOCK chu khong phai SINGLE.
//
//   Trinh tu:
//     1. enable channel -> channel cho ca hai trigger
//     2. ban 1 COMMAND trigger cho SRC (TI0) -> khoi dong lenh doc
//     3. ban chuoi BLOCK trigger cho DES (TI1), ket bang LAST_BLOCK
//     4. channel hoan tat
//==============================================================================
`ifndef DMA350_VSEQ_TRIG_SRCCMD_DESBLOCK_SV
`define DMA350_VSEQ_TRIG_SRCCMD_DESBLOCK_SV

class dma350_vseq_trig_srccmd_desblock extends dma350_vseq_trig_base;
  `uvm_object_utils(dma350_vseq_trig_srccmd_desblock)

  // xsize = 8 item, block = BLKSIZE+1 = 4 item -> 2 block (1 BLOCK + 1 LAST_BLOCK)
  int unsigned n_des_block = 1;    // so BLOCK truoc khi ban LAST_BLOCK

  function new(string name = "dma350_vseq_trig_srccmd_desblock");
    super.new(name);
    ch          = 0;
    src_addr    = 32'h0007_0000;
    des_addr    = 32'h0007_4000;
    xsize       = 8;

    // ---- SOURCE : COMMAND, cong TI0 ----
    use_srctrig = 1;
    trig_type   = TT_HW;
    trig_mode   = TM_CMD;          // <-- command cho SOURCE
    trig_sel    = 0;               // cong TI0
    blksize     = 3;

    // ---- DESTINATION : FLOW CONTROL theo BLOCK, cong TI1 ----
    use_destrig      = 1;
    separate_des_cfg = 1;          // <-- des cau hinh RIENG, khac src
    des_trig_type    = TT_HW;
    des_trig_mode    = TM_FLOW_DMA;// <-- flow control cho DESTINATION
    des_trig_sel     = 1;          // cong TI1
    des_blksize      = 3;          // block = 4 item
  endfunction

  virtual task body();
    super.body();

    cfg_trig_ch();
    log_src_des_mode();            // in ro: SRC=COMMAND, DES=FLOW_CONTROL
    enable_ch(ch);

    check_waiting_trigger("cho trigger (src command + des block)");

    // (2) SRC : 1 COMMAND trigger tren TI0 -> khoi dong lenh doc
    `uvm_info(get_type_name(),
      "SRC (COMMAND mode): gui 1 trigger khoi dong tren TI0", UVM_LOW)
    send_hw_trig(RQ_SINGLE, 1, int'(trig_sel));

    // (3) DES : chuoi BLOCK tren TI1, ket bang LAST_BLOCK
    `uvm_info(get_type_name(), $sformatf(
      "DES (FLOW CONTROL mode): gui %0d BLOCK roi LAST_BLOCK tren TI1 (block=%0d item)",
      n_des_block, des_blksize+1), UVM_LOW)
    send_hw_trig(RQ_BLOCK,      n_des_block, int'(des_trig_sel));
    send_hw_trig(RQ_LAST_BLOCK, 1,           int'(des_trig_sel));

    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_trig_srccmd_desblock

`endif // DMA350_VSEQ_TRIG_SRCCMD_DESBLOCK_SV
