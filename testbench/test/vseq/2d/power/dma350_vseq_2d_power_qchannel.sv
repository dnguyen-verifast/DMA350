//==============================================================================
// dma350_vseq_2d_power_qchannel.sv
//   GROUP J - TRM 5.9.1.2 'Clock Q-Channel' quanh lenh 2D
//   Chu ky quiesce/wake clock truoc khi chay va sau khi chay xong khung 2D.
//   Ky vong: handshake Q-Channel dung; khung 2D chay lai binh thuong sau wake.
//==============================================================================
`ifndef DMA350_VSEQ_2D_POWER_QCHANNEL_SV
`define DMA350_VSEQ_2D_POWER_QCHANNEL_SV

class dma350_vseq_2d_power_qchannel extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_power_qchannel)

  function new(string name = "dma350_vseq_2d_power_qchannel");
    super.new(name);

  endfunction

  virtual task body();
    crlp_qch_cycle_seq q;
    super.body();

    q = crlp_qch_cycle_seq::type_id::create("qch_pre");
    q.start(p_sequencer.crlp_seqr_h);

    run_2d();

    q = crlp_qch_cycle_seq::type_id::create("qch_post");
    q.start(p_sequencer.crlp_seqr_h);
  endtask

endclass : dma350_vseq_2d_power_qchannel

`endif // DMA350_VSEQ_2D_POWER_QCHANNEL_SV
