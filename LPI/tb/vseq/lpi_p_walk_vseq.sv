//==============================================================================
// lpi_p_walk_vseq.sv
// P-Channel scenario : directed power-state WALK (ON->Warm->Full ret->OFF->ON),
// device ACCEPTS so every transition completes (multiple transitions, Fig 3-7).
//==============================================================================
class lpi_p_walk_vseq extends lpi_base_vseq;
  `uvm_object_utils(lpi_p_walk_vseq)
  function new(string name="lpi_p_walk_vseq"); super.new(name); endfunction

  task body();
    lpi_pchannel_slave_accept_seq dev;     // device accepts every transition
    lpi_pchannel_master_walk_seq  ctrl;    // controller walks the power states

    dev = lpi_pchannel_slave_accept_seq::type_id::create("dev");
    fork dev.start(p_sequencer.p_slave_seqr); join_none

    ctrl = lpi_pchannel_master_walk_seq::type_id::create("ctrl");
    void'(ctrl.randomize() with { n_req == local::n_req; });
    ctrl.start(p_sequencer.p_master_seqr);

    dev.kill();
  endtask
endclass
