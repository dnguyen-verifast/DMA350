//==============================================================================
// dma350_secpriv_secure_test.sv
//   vseq: dma350_vseq_secpriv_secure
//==============================================================================
`ifndef DMA350_SECPRIV_SECURE_TEST_SV
`define DMA350_SECPRIV_SECURE_TEST_SV

class dma350_secpriv_secure_test extends dma350_base_test;
  `uvm_component_utils(dma350_secpriv_secure_test)

  function new(string name = "dma350_secpriv_secure_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_secpriv_secure vseq = dma350_vseq_secpriv_secure::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_secpriv_secure_test

`endif // DMA350_SECPRIV_SECURE_TEST_SV
