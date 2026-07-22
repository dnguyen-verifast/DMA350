//==============================================================================
// dma350_vseq_trig_bothcmd.sv
//   TRM Figure 5-15 : "Command trigger for both source and destination"
//
//   SOURCE      : TRIGMODE = COMMAND (TM_CMD), cong TI0
//   DESTINATION : TRIGMODE = COMMAND (TM_CMD), cong TI1
//
//   DIEM KIEM TRA CHINH (TRM 5.4.1.1):
//     "The DMAC waits for BOTH requests to be asserted before acknowledging them
//      to show when the command is really started."
//   -> Req den TRUOC (mac dinh: DES) KHONG duoc ack cho den khi req con lai den.
//      Trong khoang do channel van dung yen: DONE = 0, khong co AR/AW nao phat ra
//      (cmd_trigger_checker chay nen se bat neu co).
//
//   Vi finish_item() cua VIP trigger chi tra ve SAU khi hoan tat 4-phase
//   handshake (req^ -> ack^ -> req v -> ack v), hai phia PHAI ban song song
//   bang fork...join - neu ban tuan tu se treo o req dau tien.
//
//   Trinh tu:
//     1. enable channel -> channel cho ca hai trigger
//     2. ban COMMAND trigger cho DES (TI1) truoc  -> req treo, CHUA duoc ack
//     3. kiem tra channel van chua chay (DONE = 0)
//     4. ban COMMAND trigger cho SRC (TI0)        -> ca hai duoc ack, lenh chay
//     5. channel hoan tat
//==============================================================================
`ifndef DMA350_VSEQ_TRIG_BOTHCMD_SV
`define DMA350_VSEQ_TRIG_BOTHCMD_SV

class dma350_vseq_trig_bothcmd extends dma350_vseq_trig_base;
  `uvm_object_utils(dma350_vseq_trig_bothcmd)

  // Phia nao ban req truoc. 1 = DES truoc (dung nhu Figure 5-15), 0 = SRC truoc.
  bit          des_first    = 1;
  // Khoang tre giua req thu nhat va req thu hai (de quan sat trang thai "treo").
  time         second_delay = 500ns;

  function new(string name = "dma350_vseq_trig_bothcmd");
    super.new(name);
    ch          = 0;
    src_addr    = 32'h0008_0000;
    des_addr    = 32'h0008_4000;
    xsize       = 16;

    // ---- SOURCE : COMMAND, cong TI0 ----
    use_srctrig = 1;
    trig_type   = TT_HW;
    trig_mode   = TM_CMD;          // <-- command cho SOURCE
    trig_sel    = 0;               // cong TI0
    blksize     = 3;

    // ---- DESTINATION : COMMAND, cong TI1 ----
    use_destrig      = 1;
    separate_des_cfg = 1;          // des dung cong RIENG (TI1), cung mode CMD
    des_trig_type    = TT_HW;
    des_trig_mode    = TM_CMD;     // <-- command cho DESTINATION
    des_trig_sel     = 1;          // cong TI1
    des_blksize      = 3;
  endfunction

  virtual task body();
    int first_port, second_port;
    string first_name, second_name;

    super.body();

    cfg_trig_ch();
    log_src_des_mode();            // in ro: SRC=COMMAND, DES=COMMAND
    enable_ch(ch);

    check_waiting_trigger("cho trigger (src command + des command)");

    if (des_first) begin
      first_port  = int'(des_trig_sel); first_name  = "DES";
      second_port = int'(trig_sel);     second_name = "SRC";
    end
    else begin
      first_port  = int'(trig_sel);     first_name  = "SRC";
      second_port = int'(des_trig_sel); second_name = "DES";
    end

    // (2)(3)(4) hai phia ban SONG SONG: req thu nhat treo cho den khi req thu
    // hai duoc phat, luc do DMAC moi ack ca hai.
    fork
      begin : first_req
        `uvm_info(get_type_name(), $sformatf(
          "%s (COMMAND mode): gui trigger tren TI%0d - KHONG duoc ack cho den khi %s den",
          first_name, first_port, second_name), UVM_LOW)
        send_hw_trig(RQ_SINGLE, 1, first_port);
      end

      begin : check_stalled
        // Trong khi chi co MOT req: channel phai van dung yen.
        #(second_delay / 2);
        check_not_started($sformatf(
          "chi moi co req %s tren TI%0d, thieu req %s -> lenh CHUA duoc phep chay",
          first_name, first_port, second_name));
      end

      begin : second_req
        #(second_delay);
        `uvm_info(get_type_name(), $sformatf(
          "%s (COMMAND mode): gui trigger tren TI%0d - du 2 req, DMAC ack ca hai",
          second_name, second_port), UVM_LOW)
        send_hw_trig(RQ_SINGLE, 1, second_port);
      end
    join

    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

  //---------------------------------------------------------------------------
  // Channel da enable nhung PHAI chua chay: DONE = 0.
  // (Viec "chua phat AR/AW" do cmd_trigger_checker soi nen.)
  //---------------------------------------------------------------------------
  virtual task check_not_started(string why);
    bit [31:0] st;
    apb_read(ch_addr(ch,O_STATUS), st);
    `uvm_info(get_type_name(), $sformatf(
      "CH%0d STATUS=0x%08h (DONE=%0b SRCTRIGWAIT=%0b DESTRIGWAIT=%0b) - %s",
      ch, st, st[16], st[24], st[25], why), UVM_LOW)
    if (st[16])
      `uvm_error(get_type_name(), $sformatf(
        "CH%0d DONE=1 khi moi co 1 trong 2 command trigger - vi pham TRM 5.4.1.1 (phai cho CA HAI req truoc khi bat dau lenh)", ch))
  endtask

endclass : dma350_vseq_trig_bothcmd

`endif // DMA350_VSEQ_TRIG_BOTHCMD_SV
