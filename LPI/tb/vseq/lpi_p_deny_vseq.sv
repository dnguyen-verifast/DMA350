//==============================================================================
// lpi_p_deny_vseq.sv
// P-Channel scenario : controller requests transitions, device ALWAYS DENIES.
//==============================================================================
class lpi_p_deny_vseq extends lpi_base_vseq;
  `uvm_object_utils(lpi_p_deny_vseq)
  function new(string name="lpi_p_deny_vseq"); super.new(name); endfunction

  task body();
    lpi_pchannel_slave_deny_seq dev;       // device responder (always deny)
    lpi_pchannel_master_seq     ctrl;      // controller initiator

    dev = lpi_pchannel_slave_deny_seq::type_id::create("dev");
    fork dev.start(p_sequencer.p_slave_seqr); join_none

    ctrl = lpi_pchannel_master_seq::type_id::create("ctrl");
    void'(ctrl.randomize() with { n_req == local::n_req; });
    ctrl.start(p_sequencer.p_master_seqr);

    dev.kill();
  endtask
endclass
