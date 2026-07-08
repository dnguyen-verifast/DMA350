//==============================================================================
// lpi_q_deny_test.sv  -  Q-Channel, device always denies.
//==============================================================================
class lpi_q_deny_test extends lpi_base_test;
  `uvm_component_utils(lpi_q_deny_test)
  function new(string name, uvm_component parent);
    super.new(name,parent); n_req = 15;
  endfunction
  virtual function void configure(lpi_env_cfg c);
    c.enable_qchannel = 1; c.enable_pchannel = 0;
  endfunction
  task run_phase(uvm_phase phase);
    lpi_q_deny_vseq vseq;
    phase.raise_objection(this);
    vseq = lpi_q_deny_vseq::type_id::create("vseq");
    void'(vseq.randomize() with { n_req == local::n_req; });
    vseq.start(env.vseqr);
    repeat (20) @(posedge env.cfg.qvif.clk);
    phase.drop_objection(this);
  endtask
endclass
