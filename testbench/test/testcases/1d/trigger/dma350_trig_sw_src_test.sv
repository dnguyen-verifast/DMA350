//==============================================================================
// dma350_trig_sw_src_test.sv
//   Software SOURCE trigger (TRM 5.4.3): phat bang CH_CMD.SRCSWTRIGINREQ, khong dung chan ngoai.
//==============================================================================
`ifndef DMA350_TRIG_SW_SRC_TEST_SV
`define DMA350_TRIG_SW_SRC_TEST_SV

class dma350_trig_sw_src_test extends dma350_base_test;
  `uvm_component_utils(dma350_trig_sw_src_test)

  function new(string name = "dma350_trig_sw_src_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_trig_sw_src vseq = dma350_vseq_trig_sw_src::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_trig_sw_src_test

`endif // DMA350_TRIG_SW_SRC_TEST_SV
