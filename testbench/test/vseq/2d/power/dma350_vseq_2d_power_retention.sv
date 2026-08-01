//==============================================================================
// dma350_vseq_2d_power_retention.sv
//   GROUP J - TRM 5.9.1.1 'Power P-Channel' - Full retention mode quanh lenh 2D
//   Vao/ra retention TRUOC va SAU khi chay khung 2D (khi DMAC dang IDLE).
//   Ky vong: context (YSIZE/stride/dia chi) van con sau retention; khung 2D chay dung.
//==============================================================================
`ifndef DMA350_VSEQ_2D_POWER_RETENTION_SV
`define DMA350_VSEQ_2D_POWER_RETENTION_SV

class dma350_vseq_2d_power_retention extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_power_retention)

  function new(string name = "dma350_vseq_2d_power_retention");
    super.new(name);

  endfunction

  virtual task body();
    crlp_pch_seq p;
    super.body();

    // Vao retention roi ve ON khi DMAC dang idle
    p = crlp_pch_seq::type_id::create("pch_ret");
    if (!p.randomize() with { target_state == 4'h4; })   // PSTATE_RET
      `uvm_error(get_type_name(), "randomize pch RET that bai")
    p.start(p_sequencer.crlp_seqr_h);

    p = crlp_pch_seq::type_id::create("pch_on");
    if (!p.randomize() with { target_state == 4'hF; })   // PSTATE_ON_FULL
      `uvm_error(get_type_name(), "randomize pch ON that bai")
    p.start(p_sequencer.crlp_seqr_h);

    run_2d();
  endtask

endclass : dma350_vseq_2d_power_retention

`endif // DMA350_VSEQ_2D_POWER_RETENTION_SV
