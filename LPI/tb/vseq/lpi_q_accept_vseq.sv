//==============================================================================
// lpi_q_accept_vseq.sv
// Q-Channel scenario : controller issues requests, device ALWAYS ACCEPTS.
//==============================================================================
class lpi_q_accept_vseq extends lpi_base_vseq;
  `uvm_object_utils(lpi_q_accept_vseq)
  function new(string name="lpi_q_accept_vseq"); super.new(name); endfunction

  task body();
    lpi_qchannel_master_accept_seq dev;     // device responder (always accept)
    lpi_qchannel_slave_seq         ctrl;    // controller initiator

    dev = lpi_qchannel_master_accept_seq::type_id::create("dev");
    fork dev.start(p_sequencer.q_master_seqr); join_none

    ctrl = lpi_qchannel_slave_seq::type_id::create("ctrl");
    void'(ctrl.randomize() with { n_req == local::n_req; });
    ctrl.start(p_sequencer.q_slave_seqr);

    dev.kill();
  endtask
endclass
