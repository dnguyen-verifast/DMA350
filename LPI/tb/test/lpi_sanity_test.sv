//==============================================================================
// lpi_sanity_test.sv
// Bring-up / connectivity test. Runs a short directed master<->slave handshake
// on both channels to confirm the UVM environment is wired correctly before
// running the randomized smoke/regression tests. Expect: 0 UVM_ERROR.
//==============================================================================
class lpi_sanity_test extends lpi_base_test;
  `uvm_component_utils(lpi_sanity_test)
  function new(string name, uvm_component parent);
    super.new(name,parent);
    n_req = 3;                     // accept, deny, accept
  endfunction

  task run_phase(uvm_phase phase);
    lpi_sanity_vseq vseq;
    phase.raise_objection(this);

    `uvm_info(get_type_name(),
      "=== LPI environment bring-up: master(controller) <-> slave(device) ===",
      UVM_LOW)

    vseq = lpi_sanity_vseq::type_id::create("vseq");
    vseq.do_q = cfg.enable_qchannel;
    vseq.do_p = cfg.enable_pchannel;
    void'(vseq.randomize() with { n_req == local::n_req; });
    vseq.start(env.vseqr);

    repeat (20) @(posedge env.cfg.qvif.clk);   // drain
    phase.drop_objection(this);
  endtask
endclass
