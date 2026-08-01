//==============================================================================
// dma350_vseq_lifecycle_disabled.sv
//   "Disabled - Channel off"
//   - Sau reset: channel o trang thai disabled (ENABLECMD=0).
//   - Chay lenh auto-restart VO HAN roi DISABLECMD -> lenh hien tai chay xong,
//     channel ve disabled (STAT_DISABLED, ENABLECMD tu ve 0).
//==============================================================================
`ifndef DMA350_VSEQ_LIFECYCLE_DISABLED_SV
`define DMA350_VSEQ_LIFECYCLE_DISABLED_SV

class dma350_vseq_lifecycle_disabled extends dma350_vseq_lifecycle_base;
  `uvm_object_utils(dma350_vseq_lifecycle_disabled)

  function new(string name = "dma350_vseq_lifecycle_disabled");
    super.new(name);
    xsize = 32;
  endfunction

  virtual task body();
    super.body();

    // 1) sau reset: channel OFF
    check_enabled(1'b0, "sau reset (Disabled/off)");

    // 2) cau hinh + bat auto-restart vo han roi enable -> chay lien tuc
    cfg_copy();
    apb_write(ch_addr(ch,O_AUTOCFG), CMDRESTARTINFEN);
    enable_ch(ch);
    check_enabled(1'b1, "sau enable (Running)");

    // 3) DISABLECMD: ket thuc sach vong lap vo han -> ve Disabled
    apb_write(ch_addr(ch,O_CMD), 32'h1 << B_DISABLE);
    wait_ch_bit(ch, S_DISABLED, "DISABLED");
    check_enabled(1'b0, "sau DISABLECMD (Disabled)");
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_lifecycle_disabled

`endif // DMA350_VSEQ_LIFECYCLE_DISABLED_SV
