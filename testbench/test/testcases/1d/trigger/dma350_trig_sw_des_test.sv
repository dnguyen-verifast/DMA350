//==============================================================================
// dma350_trig_sw_des_test.sv
//   Software DESTINATION trigger: phat bang CH_CMD.DESSWTRIGINREQ (DESTRIGINWAIT).
//==============================================================================
`ifndef DMA350_TRIG_SW_DES_TEST_SV
`define DMA350_TRIG_SW_DES_TEST_SV

class dma350_trig_sw_des_test extends dma350_base_test;
  `uvm_component_utils(dma350_trig_sw_des_test)

  function new(string name = "dma350_trig_sw_des_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_trig_sw_des vseq = dma350_vseq_trig_sw_des::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_trig_sw_des_test

`endif // DMA350_TRIG_SW_DES_TEST_SV
