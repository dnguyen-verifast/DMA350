//==============================================================================
// dma350_vseq_lifecycle_stopped.sv
//   "Stopped - Execution stopped"
//   - Enable copy dai -> STOPCMD -> STAT_STOPPED, channel ve disabled.
//==============================================================================
`ifndef DMA350_VSEQ_LIFECYCLE_STOPPED_SV
`define DMA350_VSEQ_LIFECYCLE_STOPPED_SV

class dma350_vseq_lifecycle_stopped extends dma350_vseq_lifecycle_base;
  `uvm_object_utils(dma350_vseq_lifecycle_stopped)

  function new(string name = "dma350_vseq_lifecycle_stopped");
    super.new(name);
    xsize = 128;
  endfunction

  virtual task body();
    super.body();

    cfg_copy();
    enable_ch(ch);

    // STOP -> cho toi khi vao trang thai stopped
    apb_write(ch_addr(ch,O_CMD), 32'h1 << B_STOP);
    wait_ch_bit(ch, S_STOPPED, "STOPPED");

    // sau khi stop sach: ENABLECMD tu ve 0 (channel off)
    check_enabled(1'b0, "sau STOPCMD (Disabled)");
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_lifecycle_stopped

`endif // DMA350_VSEQ_LIFECYCLE_STOPPED_SV
