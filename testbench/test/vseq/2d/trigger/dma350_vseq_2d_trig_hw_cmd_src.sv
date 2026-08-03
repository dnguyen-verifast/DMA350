//==============================================================================
// dma350_vseq_2d_trig_hw_cmd_src.sv
//   GROUP F - TRM 5.4.1.1 'Trigger input command mode' (phia nguon) tren 2D
//   Trigger phan cung tren cong TI0 khoi dong toan bo lenh 2D.
//   Ky vong: khong co AR nao truoc handshake trigger (checker_dma_operation soi);
//            sau handshake thi ca 4 dong chay lien mach.
//==============================================================================
`ifndef DMA350_VSEQ_2D_TRIG_HW_CMD_SRC_SV
`define DMA350_VSEQ_2D_TRIG_HW_CMD_SRC_SV

class dma350_vseq_2d_trig_hw_cmd_src extends dma350_vseq_2d_trig_base;
  `uvm_object_utils(dma350_vseq_2d_trig_hw_cmd_src)

  function new(string name = "dma350_vseq_2d_trig_hw_cmd_src");
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
    check_waiting_trigger("cho HW command trigger o TI0 (2D)");
    send_src_trig(RQ_BLOCK, 1);
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_trig_hw_cmd_src

`endif // DMA350_VSEQ_2D_TRIG_HW_CMD_SRC_SV
