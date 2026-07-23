//==============================================================================
// dma350_vseq_trig_srccmd_block.sv
//   DMAC operation trigger (TRM 5.4) -- TRIGGER NGOAI (HW), cong TI0
//   SOURCE trigger mode  : COMMAND   (des trigger: KHONG dung)
//   Trigger request type : BLOCK  (gui tren cong TI0)
//
//   Command mode + BLOCK: 1 trigger cho ca block (BLKSIZE+1 item).
//==============================================================================
`ifndef DMA350_VSEQ_TRIG_SRCCMD_BLOCK_SV
`define DMA350_VSEQ_TRIG_SRCCMD_BLOCK_SV

class dma350_vseq_trig_srccmd_block extends dma350_vseq_trig_base;
  `uvm_object_utils(dma350_vseq_trig_srccmd_block)

  function new(string name = "dma350_vseq_trig_srccmd_block");
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

    // COMMAND mode: MOT trigger giai phong CA LENH, bat ke reqtype la BLOCK.
    // reqtype o day chi doi ENCODING tren chan trig_in_req_type (kiem tra DMAC
    // ack dung), KHONG doi so luong item duoc phep truyen.
    send_src_trig(RQ_BLOCK, 1);

    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_trig_srccmd_block

`endif // DMA350_VSEQ_TRIG_SRCCMD_BLOCK_SV
