//==============================================================================
// dma350_trig_bothcmd_test.sv
//   TRM Figure 5-15 : Command trigger for BOTH source and destination
//   SRC = COMMAND mode (cong TI0) | DES = COMMAND mode (cong TI1)
//   Kiem tra: DMAC chi ack khi CA HAI req da duoc phat (TRM 5.4.1.1)
//==============================================================================
`ifndef DMA350_TRIG_BOTHCMD_TEST_SV
`define DMA350_TRIG_BOTHCMD_TEST_SV

class dma350_trig_bothcmd_test extends dma350_base_test;
  `uvm_component_utils(dma350_trig_bothcmd_test)

  function new(string name = "dma350_trig_bothcmd_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_trig_bothcmd vseq = dma350_vseq_trig_bothcmd::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_trig_bothcmd_test

`endif // DMA350_TRIG_BOTHCMD_TEST_SV
