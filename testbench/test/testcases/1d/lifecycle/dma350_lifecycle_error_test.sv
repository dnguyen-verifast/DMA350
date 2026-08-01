//==============================================================================
// dma350_lifecycle_error_test.sv
//   DMA channel lifecycle / execution states (TRM 5.6) - CH0.
//   vseq: dma350_vseq_lifecycle_error
//==============================================================================
`ifndef DMA350_LIFECYCLE_ERROR_TEST_SV
`define DMA350_LIFECYCLE_ERROR_TEST_SV

class dma350_lifecycle_error_test extends dma350_base_test;
  `uvm_component_utils(dma350_lifecycle_error_test)

  function new(string name = "dma350_lifecycle_error_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_lifecycle_error vseq = dma350_vseq_lifecycle_error::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_lifecycle_error_test

`endif // DMA350_LIFECYCLE_ERROR_TEST_SV
