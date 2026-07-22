//==============================================================================
// dma350_trig_srcflow_descmd_test.sv
//   TRM Figure 5-17 : Flow control mode trigger for SOURCE and COMMAND for DESTINATION
//   SRC = FLOW CONTROL mode (cong TI0) | DES = COMMAND mode (cong TI1)
//==============================================================================
`ifndef DMA350_TRIG_SRCFLOW_DESCMD_TEST_SV
`define DMA350_TRIG_SRCFLOW_DESCMD_TEST_SV

class dma350_trig_srcflow_descmd_test extends dma350_base_test;
  `uvm_component_utils(dma350_trig_srcflow_descmd_test)

  function new(string name = "dma350_trig_srcflow_descmd_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_trig_srcflow_descmd vseq = dma350_vseq_trig_srcflow_descmd::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_trig_srcflow_descmd_test

`endif // DMA350_TRIG_SRCFLOW_DESCMD_TEST_SV
