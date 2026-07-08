//==============================================================================
// Test 9: dma350_lowpower_test - Q/P-channel LPI khi idle va khi busy
//==============================================================================
`ifndef DMA350_LOWPOWER_TEST_SV
`define DMA350_LOWPOWER_TEST_SV

class dma350_lowpower_test extends dma350_base_test;
  `uvm_component_utils(dma350_lowpower_test)

  function new(string name = "dma350_lowpower_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_lowpower vseq = dma350_vseq_lowpower::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask
endclass

`endif // DMA350_LOWPOWER_TEST_SV
