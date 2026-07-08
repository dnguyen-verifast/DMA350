//==============================================================================
// lpi_smoke_vseq.sv
// Smoke virtual sequence. Roles per channel:
//   Q-Channel : MASTER = Device (responder), SLAVE = Controller (initiator)
//   P-Channel : MASTER = Controller (initiator), SLAVE = Device (responder)
// The CONTROLLER (initiator) runs in the foreground for n_req cycles; the
// DEVICE (responder) runs forever in the background.
//==============================================================================
class lpi_smoke_vseq extends lpi_base_vseq;
  `uvm_object_utils(lpi_smoke_vseq)
  function new(string name="lpi_smoke_vseq"); super.new(name); endfunction

  task body();
    lpi_qchannel_master_seq q_dev;  lpi_qchannel_slave_seq  q_ctrl;
    lpi_pchannel_master_seq p_ctrl; lpi_pchannel_slave_seq  p_dev;

    // ---- background DEVICE responders (forever) ----
    if (do_q) begin
      q_dev = lpi_qchannel_master_seq::type_id::create("q_dev");
      fork q_dev.start(p_sequencer.q_master_seqr); join_none   // Q device = master
    end
    if (do_p) begin
      p_dev = lpi_pchannel_slave_seq::type_id::create("p_dev");
      fork p_dev.start(p_sequencer.p_slave_seqr); join_none    // P device = slave
    end

    // ---- foreground CONTROLLER initiators, both channels in parallel ----
    fork
      begin
        if (do_q) begin
          q_ctrl = lpi_qchannel_slave_seq::type_id::create("q_ctrl"); // Q controller = slave
          void'(q_ctrl.randomize() with { n_req == local::n_req; });
          q_ctrl.start(p_sequencer.q_slave_seqr);
        end
      end
      begin
        if (do_p) begin
          p_ctrl = lpi_pchannel_master_seq::type_id::create("p_ctrl"); // P controller = master
          void'(p_ctrl.randomize() with { n_req == local::n_req; });
          p_ctrl.start(p_sequencer.p_master_seqr);
        end
      end
    join

    // ---- stop the forever responders ----
    if (do_q && q_dev != null) q_dev.kill();
    if (do_p && p_dev != null) p_dev.kill();
  endtask
endclass
