//==============================================================================
// dma350_vseq_2d_trig_sw_cmd.sv
//   GROUP F - TRM 5.4.5 'Software triggers' tren lenh 2D
//   Command-mode trigger bang phan mem (CH_CMD.SRCSWTRIGINREQ) khoi dong ca khoi 2D.
//   Ky vong: truoc SW trigger channel dung o SRCTRIGINWAIT; sau trigger chay het 4 dong.
//==============================================================================
`ifndef DMA350_VSEQ_2D_TRIG_SW_CMD_SV
`define DMA350_VSEQ_2D_TRIG_SW_CMD_SV

class dma350_vseq_2d_trig_sw_cmd extends dma350_vseq_2d_trig_base;
  `uvm_object_utils(dma350_vseq_2d_trig_sw_cmd)

  function new(string name = "dma350_vseq_2d_trig_sw_cmd");
    super.new(name);
    use_srctrig = 1;
    trig_type = TT_SW;
    trig_mode = TM_CMD;
  endfunction

  virtual task body();
    super.body();
    cfg_trig_ch();
    enable_ch(ch);
    check_waiting_trigger("cho SW command trigger (2D)");
    send_sw_srctrig(RQ_SINGLE);
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_trig_sw_cmd

`endif // DMA350_VSEQ_2D_TRIG_SW_CMD_SV
