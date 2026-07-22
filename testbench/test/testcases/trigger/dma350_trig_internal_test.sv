//==============================================================================
// dma350_trig_internal_test.sv
//   Internal trigger connection (TRM 5.4.4): CH0 xong -> phat trigger noi bo -> CH1 moi chay.
//==============================================================================
`ifndef DMA350_TRIG_INTERNAL_TEST_SV
`define DMA350_TRIG_INTERNAL_TEST_SV

class dma350_trig_internal_test extends dma350_base_test;
  `uvm_component_utils(dma350_trig_internal_test)

  function new(string name = "dma350_trig_internal_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_trig_internal vseq = dma350_vseq_trig_internal::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_trig_internal_test

`endif // DMA350_TRIG_INTERNAL_TEST_SV
