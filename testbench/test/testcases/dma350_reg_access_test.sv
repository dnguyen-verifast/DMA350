//==============================================================================
// Test 1: dma350_reg_access_test - ghi/doc-lai thanh ghi config qua APB
//==============================================================================
`ifndef DMA350_REG_ACCESS_TEST_SV
`define DMA350_REG_ACCESS_TEST_SV

class dma350_reg_access_test extends dma350_base_test;
  `uvm_component_utils(dma350_reg_access_test)

  function new(string name = "dma350_reg_access_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_reg_access vseq = dma350_vseq_reg_access::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;   // drain: cho monitor/scoreboard xu ly not giao dich cuoi
    phase.drop_objection(this, get_type_name());
  endtask
endclass

`endif // DMA350_REG_ACCESS_TEST_SV
