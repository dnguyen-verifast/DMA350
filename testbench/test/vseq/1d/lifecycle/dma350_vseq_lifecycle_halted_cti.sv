//==============================================================================
// dma350_vseq_lifecycle_halted_cti.sv
//   "Halted (CTI debug) - Halted for debug via CTI"
//   - Enable copy dai; qua Cross Trigger Interface: halt_req -> DMAC vao trang
//     thai halted (paused) -> restart_req -> tiep tuc -> DONE.
//   Dung dma350_sc_cti_seq (self-contained halt/restart) tren SC agent.
//==============================================================================
`ifndef DMA350_VSEQ_LIFECYCLE_HALTED_CTI_SV
`define DMA350_VSEQ_LIFECYCLE_HALTED_CTI_SV

class dma350_vseq_lifecycle_halted_cti extends dma350_vseq_lifecycle_base;
  `uvm_object_utils(dma350_vseq_lifecycle_halted_cti)

  function new(string name = "dma350_vseq_lifecycle_halted_cti");
    super.new(name);
    xsize = 128;
  endfunction

  virtual task body();
    super.body();

    cfg_copy();
    enable_ch(ch);
    check_enabled(1'b1, "Running truoc CTI halt");

    // CTI halt -> cho `halted` -> restart (auto). Kenh tiep tuc sau restart.
    if (p_sequencer.sc_seqr_h == null)
      `uvm_error(get_type_name(), "sc_seqr_h = null (SC agent passive?) - khong CTI duoc")
    else begin
      dma350_sc_cti_seq cti = dma350_sc_cti_seq::type_id::create("cti_halt");
      if (!cti.randomize() with { halt_len == 30; auto_restart == 1'b1; })
        `uvm_error(get_type_name(), "randomize dma350_sc_cti_seq that bai")
      cti.start(p_sequencer.sc_seqr_h);
    end

    // sau restart: kenh chay tiep den DONE
    wait_ch_done(ch);
    check_enabled(1'b0, "sau DONE (Disabled)");
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_lifecycle_halted_cti

`endif // DMA350_VSEQ_LIFECYCLE_HALTED_CTI_SV
