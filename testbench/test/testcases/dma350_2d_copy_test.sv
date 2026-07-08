//==============================================================================
// Test 4: dma350_2d_copy_test - copy 2D (4 dong x 8 word, co stride)
//==============================================================================
`ifndef DMA350_2D_COPY_TEST_SV
`define DMA350_2D_COPY_TEST_SV

class dma350_2d_copy_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_copy_test)

  function new(string name = "dma350_2d_copy_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_copy vseq = dma350_vseq_2d_copy::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask
endclass

`endif // DMA350_2D_COPY_TEST_SV
