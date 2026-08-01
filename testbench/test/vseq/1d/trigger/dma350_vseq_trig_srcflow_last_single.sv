//==============================================================================
// dma350_vseq_trig_srcflow_last_single.sv
//   DMAC operation trigger (TRM 5.4) -- TRIGGER NGOAI (HW), cong TI0
//   SOURCE trigger mode  : FLOW CONTROL   (des trigger: KHONG dung)
//   Trigger request type : LAST_SINGLE  (gui tren cong TI0)
//
//   Flow-control mode + LAST_SINGLE: item cuoi -> LAST_OKAY, ket thuc transfer.
//==============================================================================
`ifndef DMA350_VSEQ_TRIG_SRCFLOW_LAST_SINGLE_SV
`define DMA350_VSEQ_TRIG_SRCFLOW_LAST_SINGLE_SV

class dma350_vseq_trig_srcflow_last_single extends dma350_vseq_trig_base;
  `uvm_object_utils(dma350_vseq_trig_srcflow_last_single)

  function new(string name = "dma350_vseq_trig_srcflow_last_single");
    super.new(name);
    ch          = 0;
    xsize       = 16;
    use_srctrig = 1;
    trig_type   = TT_HW;        // dung chan trig_in_* ngoai
    trig_mode   = TM_FLOW_DMA;
    trig_sel    = 0;            // cong TI0 -> trig_agt_t0
    blksize     = 3;          // block = BLKSIZE+1
  endfunction

  virtual task body();
    super.body();               // POR + responder AXI5/AXIS

    cfg_trig_ch();
    enable_ch(ch);

    // Channel PHAI dung cho trigger, chua duoc tu chay.
    // (cmd_trigger_checker chay nen cung soi "AR du lieu truoc handshake")
    check_waiting_trigger("cho trigger dau tien");

    // FLOW CONTROL: moi trigger la 1 CREDIT (SINGLE = 1 item), va mot request
    // LAST con DONG LENH ngay sau credit cua no (RTL: "a LAST request
    // additionally closes the command after its block").
    // => chi ban 1 LAST_SINGLE thi lenh dong sau 1 item trong khi xsize=16
    //    -> moi truyen 1/16, scoreboard bao thieu byte (loi OAN, khong phai RTL).
    // Dung: 15 SINGLE (credit) roi 1 LAST_SINGLE de dong dung o item thu 16.
    send_src_trig(RQ_SINGLE,      xsize - 1);
    send_src_trig(RQ_LAST_SINGLE, 1);

    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_trig_srcflow_last_single

`endif // DMA350_VSEQ_TRIG_SRCFLOW_LAST_SINGLE_SV
