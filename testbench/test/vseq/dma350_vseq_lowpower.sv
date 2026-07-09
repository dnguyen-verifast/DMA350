//==============================================================================
// dma350_vseq_lowpower.sv
//   Low-power : Q-channel quiesce/wake + P-channel khi IDLE; thu khi BUSY.
//   (scoreboard process_lpi kiem: low-power ACCEPT khi busy = loi)
//==============================================================================
`ifndef DMA350_VSEQ_LOWPOWER_SV
`define DMA350_VSEQ_LOWPOWER_SV

class dma350_vseq_lowpower extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_lowpower)
  function new(string name="dma350_vseq_lowpower"); super.new(name); endfunction

  virtual task body();
    super.body();

    // ---- idle: quiesce/wake phai duoc chap nhan ----
    begin
      crlp_qch_cycle_seq q = crlp_qch_cycle_seq::type_id::create("qch_idle");
      q.start(p_sequencer.crlp_seqr_h);
    end

    // ---- busy: bat 1 copy dai roi xin quiesce (mong doi DENY) ----
    cfg_ch_1d(.ch(0), .src(32'h0004_0000), .des(32'h0004_4000), .xsize(64));
    enable_ch(0);
    begin
      crlp_qch_cycle_seq q = crlp_qch_cycle_seq::type_id::create("qch_busy");
      q.start(p_sequencer.crlp_seqr_h);
    end
    wait_ch_done(0);
    clear_ch_status(0);

    // ---- P-channel ve ON (luon accept) ----
    begin
      crlp_pch_seq p = crlp_pch_seq::type_id::create("pch_on");
      if (!p.randomize() with { target_state == PSTATE_ON_FULL; })
        `uvm_error(get_type_name(), "randomize pch failed")
      p.start(p_sequencer.crlp_seqr_h);
    end
  endtask
endclass

`endif // DMA350_VSEQ_LOWPOWER_SV
