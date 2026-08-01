//==============================================================================
// dma350_vseq_2d_trig_hw_cmd_des.sv
//   GROUP F - TRM 5.4.1.1, command trigger o PHIA DICH tren lenh 2D
//   Chi bat USEDESTRIGIN: phia ghi cho trigger, phia doc duoc chay truoc de nap FIFO.
//   Ky vong: DESTRIGINWAIT set truoc trigger; sau trigger thi ghi het vung dich.
//==============================================================================
`ifndef DMA350_VSEQ_2D_TRIG_HW_CMD_DES_SV
`define DMA350_VSEQ_2D_TRIG_HW_CMD_DES_SV

class dma350_vseq_2d_trig_hw_cmd_des extends dma350_vseq_2d_trig_base;
  `uvm_object_utils(dma350_vseq_2d_trig_hw_cmd_des)

  function new(string name = "dma350_vseq_2d_trig_hw_cmd_des");
    super.new(name);
    use_srctrig = 0;
    use_destrig = 1;
    separate_des_cfg = 1;
    des_trig_type = TT_HW;
    des_trig_mode = TM_CMD;
    des_trig_sel = 8'd1;
  endfunction

  virtual task body();
    super.body();
    cfg_trig_ch();
    enable_ch(ch);
    check_waiting_trigger("cho HW command trigger phia DES o TI1 (2D)");
    send_des_trig(RQ_BLOCK, 1);
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_trig_hw_cmd_des

`endif // DMA350_VSEQ_2D_TRIG_HW_CMD_DES_SV
