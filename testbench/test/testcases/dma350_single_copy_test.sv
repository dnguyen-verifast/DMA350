//==============================================================================
// Test 2: dma350_single_copy_test - copy 1D 64 byte channel 0
//==============================================================================
`ifndef DMA350_SINGLE_COPY_TEST_SV
`define DMA350_SINGLE_COPY_TEST_SV

class dma350_single_copy_test extends dma350_base_test;
  `uvm_component_utils(dma350_single_copy_test)

  function new(string name = "dma350_single_copy_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_single_copy vseq = dma350_vseq_single_copy::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask
endclass

`endif // DMA350_SINGLE_COPY_TEST_SV
