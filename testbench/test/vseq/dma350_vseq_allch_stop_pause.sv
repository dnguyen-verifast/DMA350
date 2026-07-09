//==============================================================================
// dma350_vseq_allch_stop_pause.sv
//   All-channel stop/pause qua Status/Control agent (4-phase handshake pin).
//==============================================================================
`ifndef DMA350_VSEQ_ALLCH_STOP_PAUSE_SV
`define DMA350_VSEQ_ALLCH_STOP_PAUSE_SV

class dma350_vseq_allch_stop_pause extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_allch_stop_pause)
  function new(string name="dma350_vseq_allch_stop_pause"); super.new(name); endfunction

  virtual task body();
    super.body();

    // chay 2 channel de stop/pause co doi tuong tac dong
    cfg_ch(.ch(0), .src(32'h0003_0000), .des(32'h0003_4000), .xsize(64));
    cfg_ch(.ch(1), .src(32'h0003_8000), .des(32'h0003_C000), .xsize(64));
    enable_ch(0);
    enable_ch(1);

    // allch PAUSE (nonsec) -> DUT keo ack; sau do allch STOP
    begin
      dma350_sc_pause_seq ps = dma350_sc_pause_seq::type_id::create("allch_pause");
      ps.start(p_sequencer.sc_seqr_h);
    end
    begin
      dma350_sc_stop_seq ss = dma350_sc_stop_seq::type_id::create("allch_stop");
      ss.start(p_sequencer.sc_seqr_h);
    end

    wait_ch_bit(0, S_STOPPED, "STOPPED(allch)");
    wait_ch_bit(1, S_STOPPED, "STOPPED(allch)");
    clear_ch_status(0);
    clear_ch_status(1);
  endtask
endclass

`endif // DMA350_VSEQ_ALLCH_STOP_PAUSE_SV
