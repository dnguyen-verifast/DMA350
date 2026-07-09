//==============================================================================
// dma350_vseq_stop_pause.sv
//   Stop / Pause : PAUSE -> STAT_PAUSED -> RESUME -> DONE ; lenh 2: STOP.
//==============================================================================
`ifndef DMA350_VSEQ_STOP_PAUSE_SV
`define DMA350_VSEQ_STOP_PAUSE_SV

class dma350_vseq_stop_pause extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_stop_pause)
  function new(string name="dma350_vseq_stop_pause"); super.new(name); endfunction

  virtual task body();
    bit [31:0] st;
    super.body();

    // ---- lenh 1: copy dai, pause giua chung roi resume ----
    cfg_ch_1d(.ch(0), .src(32'h0000_8000), .des(32'h0000_9000), .xsize(64));
    enable_ch(0);
    apb_write(ch_addr(0,O_CMD), 32'h1 << B_PAUSE);
    wait_ch_bit(0, S_PAUSED, "PAUSED");
    apb_write(ch_addr(0,O_CMD), 32'h1 << B_RESUME);
    wait_ch_done(0);
    clear_ch_status(0);

    // ---- lenh 2: copy dai, stop giua chung ----
    cfg_ch_1d(.ch(0), .src(32'h0000_A000), .des(32'h0000_B000), .xsize(64));
    enable_ch(0);
    apb_write(ch_addr(0,O_CMD), 32'h1 << B_STOP);
    wait_ch_bit(0, S_STOPPED, "STOPPED");
    clear_ch_status(0);
  endtask
endclass

`endif // DMA350_VSEQ_STOP_PAUSE_SV
