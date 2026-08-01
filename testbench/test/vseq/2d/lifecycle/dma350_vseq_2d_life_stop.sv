//==============================================================================
// dma350_vseq_2d_life_stop.sv
//   GROUP I - TRM 5.6 'Stopped state' + 4.8.2 tren lenh 2D
//   STOPCMD giua khung -> dung sach, khong ghi them ngoai diem dung.
//   Ky vong: STAT_STOPPED set; ENABLECMD ve 0; khung dich giu nguyen phan da ghi.
//==============================================================================
`ifndef DMA350_VSEQ_2D_LIFE_STOP_SV
`define DMA350_VSEQ_2D_LIFE_STOP_SV

class dma350_vseq_2d_life_stop extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_life_stop)

  function new(string name = "dma350_vseq_2d_life_stop");
    super.new(name);
    src_xsize = 32;
    des_xsize = 32;
    src_ysize = 16;
    des_ysize = 16;
    src_ystride = 'h100;
    des_ystride = 'h100;
  endfunction

  virtual task body();
    bit [31:0] cmd, ys;
    super.body();
    cfg_2d();
    enable_ch(ch);

    apb_write(ch_addr(ch,O_CMD), 32'h1 << B_STOP);
    wait_ch_bit(ch, S_STOPPED, "STOPPED giua khung 2D");

    apb_read(ch_addr(ch,O_CMD),   cmd);
    apb_read(ch_addr(ch,O_YSIZE), ys);
    if (cmd[B_ENABLE] !== 1'b0)
      `uvm_error(get_type_name(), $sformatf(
        "CH%0d sau STOP van con ENABLECMD=1 (CH_CMD=0x%08h)", ch, cmd))
    `uvm_info(get_type_name(), $sformatf(
      "CH%0d STOPPED tai dong: SRCYSIZE=%0d DESYSIZE=%0d", ch, ys[15:0], ys[31:16]), UVM_LOW)
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_life_stop

`endif // DMA350_VSEQ_2D_LIFE_STOP_SV
