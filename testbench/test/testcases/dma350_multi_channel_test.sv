//==============================================================================
// Test 6: dma350_multi_channel_test - 4 channel copy song song
//==============================================================================
`ifndef DMA350_MULTI_CHANNEL_TEST_SV
`define DMA350_MULTI_CHANNEL_TEST_SV

class dma350_multi_channel_test extends dma350_base_test;
  `uvm_component_utils(dma350_multi_channel_test)

  function new(string name = "dma350_multi_channel_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_multi_channel vseq = dma350_vseq_multi_channel::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.num_ch = 4;
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask
endclass

`endif // DMA350_MULTI_CHANNEL_TEST_SV
