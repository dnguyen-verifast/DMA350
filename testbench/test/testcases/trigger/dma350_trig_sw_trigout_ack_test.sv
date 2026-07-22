//==============================================================================
// dma350_trig_sw_trigout_ack_test.sv
//   Software ack cho trigger-out: tat auto-ack -> channel treo TRIGOUTACKWAIT -> SWTRIGOUTACK moi xong.
//==============================================================================
`ifndef DMA350_TRIG_SW_TRIGOUT_ACK_TEST_SV
`define DMA350_TRIG_SW_TRIGOUT_ACK_TEST_SV

class dma350_trig_sw_trigout_ack_test extends dma350_base_test;
  `uvm_component_utils(dma350_trig_sw_trigout_ack_test)

  function new(string name = "dma350_trig_sw_trigout_ack_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_trig_sw_trigout_ack vseq = dma350_vseq_trig_sw_trigout_ack::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_trig_sw_trigout_ack_test

`endif // DMA350_TRIG_SW_TRIGOUT_ACK_TEST_SV
