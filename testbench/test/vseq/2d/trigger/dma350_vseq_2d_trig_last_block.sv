//==============================================================================
// dma350_vseq_2d_trig_last_block.sv
//   GROUP F - TRM Table 5-4, reqtype = LAST BLOCK tren command trigger 2D
//   Peripheral bao ket thuc bang LAST_BLOCK ngay tu request dau tien.
//   Ky vong: DMAC ack bang LAST OKAY (acktype = 2'b10) va chay het khoi 2D.
//==============================================================================
`ifndef DMA350_VSEQ_2D_TRIG_LAST_BLOCK_SV
`define DMA350_VSEQ_2D_TRIG_LAST_BLOCK_SV

class dma350_vseq_2d_trig_last_block extends dma350_vseq_2d_trig_base;
  `uvm_object_utils(dma350_vseq_2d_trig_last_block)

  function new(string name = "dma350_vseq_2d_trig_last_block");
    super.new(name);
    use_srctrig = 1;
    trig_type = TT_HW;
    trig_mode = TM_CMD;
    trig_sel = 8'd0;
  endfunction

  virtual task body();
    super.body();
    cfg_trig_ch();
    enable_ch(ch);
    check_waiting_trigger("cho LAST_BLOCK command trigger (2D)");
    send_src_trig(RQ_LAST_BLOCK, 1);
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_trig_last_block

`endif // DMA350_VSEQ_2D_TRIG_LAST_BLOCK_SV
