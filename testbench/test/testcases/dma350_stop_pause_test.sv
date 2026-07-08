//==============================================================================
// Test 7: dma350_stop_pause_test - PAUSE/RESUME va STOP qua CH_CMD
//==============================================================================
`ifndef DMA350_STOP_PAUSE_TEST_SV
`define DMA350_STOP_PAUSE_TEST_SV

class dma350_stop_pause_test extends dma350_base_test;
  `uvm_component_utils(dma350_stop_pause_test)

  function new(string name = "dma350_stop_pause_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_stop_pause vseq = dma350_vseq_stop_pause::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask
endclass

`endif // DMA350_STOP_PAUSE_TEST_SV
