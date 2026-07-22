//==============================================================================
// dma350_vseq_trig_srccmd_single.sv
//   DMAC operation trigger (TRM 5.4) -- TRIGGER NGOAI (HW), cong TI0
//   SOURCE trigger mode  : COMMAND   (des trigger: KHONG dung)
//   Trigger request type : SINGLE  (gui tren cong TI0)
//
//   Command mode + SINGLE: 1 trigger khoi dong lenh; DMAC ack OKAY.
//==============================================================================
`ifndef DMA350_VSEQ_TRIG_SRCCMD_SINGLE_SV
`define DMA350_VSEQ_TRIG_SRCCMD_SINGLE_SV

class dma350_vseq_trig_srccmd_single extends dma350_vseq_trig_base;
  `uvm_object_utils(dma350_vseq_trig_srccmd_single)

  function new(string name = "dma350_vseq_trig_srccmd_single");
    super.new(name);
    ch          = 0;
    xsize       = 16;
    use_srctrig = 1;
    trig_type   = TT_HW;        // dung chan trig_in_* ngoai
    trig_mode   = TM_CMD;
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

    send_hw_trig(RQ_SINGLE, 16);

    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_trig_srccmd_single

`endif // DMA350_VSEQ_TRIG_SRCCMD_SINGLE_SV
