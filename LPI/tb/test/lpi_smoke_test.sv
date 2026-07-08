//==============================================================================
// lpi_smoke_test.sv  -  both channels via the smoke virtual sequence
//==============================================================================
class lpi_smoke_test extends lpi_base_test;
  `uvm_component_utils(lpi_smoke_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  task run_phase(uvm_phase phase);
    lpi_smoke_vseq vseq;
    phase.raise_objection(this);

    vseq = lpi_smoke_vseq::type_id::create("vseq");
    vseq.do_q = cfg.enable_qchannel;
    vseq.do_p = cfg.enable_pchannel;
    void'(vseq.randomize() with { n_req == local::n_req; });
    vseq.start(env.vseqr);

    repeat (20) @(posedge env.cfg.qvif.clk);   // drain
    phase.drop_objection(this);
  endtask
endclass
