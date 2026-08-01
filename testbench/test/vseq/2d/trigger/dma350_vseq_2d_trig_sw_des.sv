//==============================================================================
// dma350_vseq_2d_trig_sw_des.sv
//   GROUP F - TRM 5.4.5.1, SW trigger phia DICH tren lenh 2D
//   Chi phia dich cho trigger, dieu khien bang CH_CMD.DESSWTRIGINREQ.
//   Ky vong: DESTRIGINWAIT set; sau SW trigger thi ghi het vung dich 2D.
//==============================================================================
`ifndef DMA350_VSEQ_2D_TRIG_SW_DES_SV
`define DMA350_VSEQ_2D_TRIG_SW_DES_SV

class dma350_vseq_2d_trig_sw_des extends dma350_vseq_2d_trig_base;
  `uvm_object_utils(dma350_vseq_2d_trig_sw_des)

  function new(string name = "dma350_vseq_2d_trig_sw_des");
    super.new(name);
    use_srctrig = 0;
    use_destrig = 1;
    separate_des_cfg = 1;
    des_trig_type = TT_SW;
    des_trig_mode = TM_CMD;
  endfunction

  virtual task body();
    super.body();
    cfg_trig_ch();
    enable_ch(ch);
    check_waiting_trigger("cho SW des-trigger (2D)");
    send_sw_destrig(RQ_SINGLE);
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_trig_sw_des

`endif // DMA350_VSEQ_2D_TRIG_SW_DES_SV
