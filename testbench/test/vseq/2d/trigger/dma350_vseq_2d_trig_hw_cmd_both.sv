//==============================================================================
// dma350_vseq_2d_trig_hw_cmd_both.sv
//   GROUP F - TRM 5.4.1.1 Figure 5-15 'Command trigger for both source and destination'
//   Ca hai phia dung command trigger, tren HAI cong TI khac nhau (tranh trigger
//   selection error theo TRM 5.6.3). DMAC cho DU CA HAI req roi moi ack.
//   Ky vong: khong ack som; lenh 2D chi chay sau khi ca hai handshake xong.
//==============================================================================
`ifndef DMA350_VSEQ_2D_TRIG_HW_CMD_BOTH_SV
`define DMA350_VSEQ_2D_TRIG_HW_CMD_BOTH_SV

class dma350_vseq_2d_trig_hw_cmd_both extends dma350_vseq_2d_trig_base;
  `uvm_object_utils(dma350_vseq_2d_trig_hw_cmd_both)

  function new(string name = "dma350_vseq_2d_trig_hw_cmd_both");
    super.new(name);
    use_srctrig = 1;
    trig_type = TT_HW;
    trig_mode = TM_CMD;
    trig_sel = 8'd0;
    use_destrig = 1;
    separate_des_cfg = 1;
    des_trig_type = TT_HW;
    des_trig_mode = TM_CMD;
    des_trig_sel = 8'd1;
  endfunction

  virtual task body();
    super.body();
    cfg_trig_ch();
    log_src_des_mode();
    enable_ch(ch);
    check_waiting_trigger("cho CA HAI command trigger (2D)");
    send_both_trig(RQ_BLOCK, RQ_BLOCK, 1, 1, 1, 20ns);
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_trig_hw_cmd_both

`endif // DMA350_VSEQ_2D_TRIG_HW_CMD_BOTH_SV
