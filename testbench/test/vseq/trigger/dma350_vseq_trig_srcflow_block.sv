//==============================================================================
// dma350_vseq_trig_srcflow_block.sv
//   DMAC operation trigger (TRM 5.4) -- TRIGGER NGOAI (HW), cong TI0
//   SOURCE trigger mode  : FLOW CONTROL   (des trigger: KHONG dung)
//   Trigger request type : BLOCK  (gui tren cong TI0)
//
//   Flow-control mode + BLOCK: moi trigger cap phep 1 block (BLKSIZE+1 item).
//==============================================================================
`ifndef DMA350_VSEQ_TRIG_SRCFLOW_BLOCK_SV
`define DMA350_VSEQ_TRIG_SRCFLOW_BLOCK_SV

class dma350_vseq_trig_srcflow_block extends dma350_vseq_trig_base;
  `uvm_object_utils(dma350_vseq_trig_srcflow_block)

  function new(string name = "dma350_vseq_trig_srcflow_block");
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

    // FLOW CONTROL: moi BLOCK = (BLKSIZE+1) credit. Cap du xsize/(BLKSIZE+1)
    // block thi lenh tu ket thuc -> KHONG can request LAST.
    // xsize=16, block=4 -> 4 trigger BLOCK.
    send_src_trig(RQ_BLOCK, xsize / (blksize + 1));

    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_trig_srcflow_block

`endif // DMA350_VSEQ_TRIG_SRCFLOW_BLOCK_SV
