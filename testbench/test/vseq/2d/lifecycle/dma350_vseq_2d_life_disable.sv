//==============================================================================
// dma350_vseq_2d_life_disable.sv
//   GROUP I - TRM 5.6.1 'Done state' + DISABLECMD tren 2D
//   DISABLECMD cho lenh 2D dang chay HOAN THANH roi moi dung (khong nap lenh ke).
//   Ky vong: STAT_DISABLED set sau khi khung 2D chay xong tron ven.
//==============================================================================
`ifndef DMA350_VSEQ_2D_LIFE_DISABLE_SV
`define DMA350_VSEQ_2D_LIFE_DISABLE_SV

class dma350_vseq_2d_life_disable extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_life_disable)

  function new(string name = "dma350_vseq_2d_life_disable");
    super.new(name);
    src_xsize = 16;
    des_xsize = 16;
    src_ysize = 8;
    des_ysize = 8;
    src_ystride = 'h80;
    des_ystride = 'h80;
  endfunction

  virtual task body();
    bit [31:0] st;
    super.body();
    cfg_2d();
    enable_ch(ch);

    apb_write(ch_addr(ch,O_CMD), 32'h1 << B_DISABLE);
    wait_ch_bit(ch, S_DISABLED, "DISABLED sau khi khung 2D xong");

    apb_read(ch_addr(ch,O_STATUS), st);
    `uvm_info(get_type_name(), $sformatf(
      "CH%0d STATUS sau DISABLECMD = 0x%08h (DONE=%0b DISABLED=%0b)",
      ch, st, st[S_DONE], st[S_DISABLED]), UVM_LOW)
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_life_disable

`endif // DMA350_VSEQ_2D_LIFE_DISABLE_SV
