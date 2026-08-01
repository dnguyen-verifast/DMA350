//==============================================================================
// dma350_vseq_2d_life_pause_resume.sv
//   GROUP I - TRM 5.6 'Paused state' tren lenh 2D dai
//   PAUSECMD giua chung -> STAT_PAUSED -> RESUMECMD -> chay tiep den DONE.
//   Ky vong: resume dung dia chi X/Y dang do; khong lap lai, khong mat dong nao.
//==============================================================================
`ifndef DMA350_VSEQ_2D_LIFE_PAUSE_RESUME_SV
`define DMA350_VSEQ_2D_LIFE_PAUSE_RESUME_SV

class dma350_vseq_2d_life_pause_resume extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_life_pause_resume)

  function new(string name = "dma350_vseq_2d_life_pause_resume");
    super.new(name);
    src_xsize = 32;
    des_xsize = 32;
    src_ysize = 16;
    des_ysize = 16;
    src_ystride = 'h100;
    des_ystride = 'h100;
  endfunction

  virtual task body();
    bit [31:0] st, xs, ys;
    super.body();

    cfg_2d();
    enable_ch(ch);

    apb_write(ch_addr(ch,O_CMD), 32'h1 << B_PAUSE);
    wait_ch_bit(ch, S_PAUSED, "PAUSED giua khung 2D");

    // TRM 5.6.4: khi PAUSED, X/Y size cho biet toa do dang do
    apb_read(ch_addr(ch,O_XSIZE), xs);
    apb_read(ch_addr(ch,O_YSIZE), ys);
    `uvm_info(get_type_name(), $sformatf(
      "CH%0d PAUSED tai toa do: SRCX=%0d DESX=%0d SRCY=%0d DESY=%0d",
      ch, xs[15:0], xs[31:16], ys[15:0], ys[31:16]), UVM_LOW)

    apb_read(ch_addr(ch,O_STATUS), st);
    if (!st[S_RESUMEWAIT])
      `uvm_info(get_type_name(), $sformatf(
        "CH%0d PAUSED nhung STAT_RESUMEWAIT chua set (STATUS=0x%08h)", ch, st), UVM_MEDIUM)

    apb_write(ch_addr(ch,O_CMD), 32'h1 << B_RESUME);
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_life_pause_resume

`endif // DMA350_VSEQ_2D_LIFE_PAUSE_RESUME_SV
