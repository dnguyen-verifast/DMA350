//============================================================================
// dma_trig_base_test.sv
// Base test: builds the env and supplies the ack-semantics mode template cfg.
// Port counts (NUM_TRIGGER_IN/OUT) come from the testbench top (config_db).
//============================================================================
`ifndef DMA_TRIG_BASE_TEST_SV
`define DMA_TRIG_BASE_TEST_SV

class dma_trig_base_test extends uvm_test;
  `uvm_component_utils(dma_trig_base_test)

  dma_trig_env env;
  dma_trig_cfg cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Override to change ack-semantics mode / block size / coverage.
  virtual function void configure();
    cfg = dma_trig_cfg::type_id::create("cfg");
    cfg.mode = DMA_TRIG_MODE_CMD;   // command-mode acktype semantics
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    configure();
    uvm_config_db#(dma_trig_cfg)::set(this, "env", "cfg", cfg);
    env = dma_trig_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction
endclass : dma_trig_base_test

`endif // DMA_TRIG_BASE_TEST_SV
