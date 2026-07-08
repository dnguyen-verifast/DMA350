//==============================================================================
// lpi_p_walk_test.sv  -  P-Channel, directed power-state walk (ON/Warm/Ret/OFF).
//==============================================================================
class lpi_p_walk_test extends lpi_base_test;
  `uvm_component_utils(lpi_p_walk_test)
  function new(string name, uvm_component parent);
    super.new(name,parent); n_req = 12;          // ~2.5 full walks
  endfunction
  virtual function void configure(lpi_env_cfg c);
    c.enable_qchannel = 0; c.enable_pchannel = 1;
  endfunction
  task run_phase(uvm_phase phase);
    lpi_p_walk_vseq vseq;
    phase.raise_objection(this);
    vseq = lpi_p_walk_vseq::type_id::create("vseq");
    void'(vseq.randomize() with { n_req == local::n_req; });
    vseq.start(env.vseqr);
    repeat (20) @(posedge env.cfg.qvif.clk);
    phase.drop_objection(this);
  endtask
endclass
