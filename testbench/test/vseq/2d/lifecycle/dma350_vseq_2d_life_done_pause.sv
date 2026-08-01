//==============================================================================
// dma350_vseq_2d_life_done_pause.sv
//   GROUP I - TRM 6.5.1.4 DONEPAUSEEN tren lenh 2D
//   DONEPAUSEEN = 1: khi STAT_DONE len thi channel tu dong vao trang thai paused.
//   Ky vong: sau khung 2D thi STAT_PAUSED + STAT_RESUMEWAIT set, cho RESUMECMD.
//==============================================================================
`ifndef DMA350_VSEQ_2D_LIFE_DONE_PAUSE_SV
`define DMA350_VSEQ_2D_LIFE_DONE_PAUSE_SV

class dma350_vseq_2d_life_done_pause extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_life_done_pause)

  function new(string name = "dma350_vseq_2d_life_done_pause");
    super.new(name);
    donepauseen = 1;
  endfunction

  virtual task body();
    bit [31:0] st;
    super.body();
    cfg_2d();
    enable_ch(ch);

    wait_ch_bit(ch, S_PAUSED, "PAUSED tu dong sau DONE (DONEPAUSEEN)");
    apb_read(ch_addr(ch,O_STATUS), st);
    if (!st[S_DONE])
      `uvm_error(get_type_name(), $sformatf(
        "CH%0d paused vi DONEPAUSEEN nhung STAT_DONE=0 (STATUS=0x%08h)", ch, st))

    apb_write(ch_addr(ch,O_CMD), 32'h1 << B_RESUME);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_life_done_pause

`endif // DMA350_VSEQ_2D_LIFE_DONE_PAUSE_SV
