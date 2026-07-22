//==============================================================================
// dma350_trig_srccmd_desblock_test.sv
//   TRM Figure 5-18 : COMMAND trigger for SOURCE and BLOCK for DESTINATION
//   SRC = COMMAND mode (cong TI0) | DES = FLOW CONTROL mode, reqtype BLOCK (cong TI1)
//==============================================================================
`ifndef DMA350_TRIG_SRCCMD_DESBLOCK_TEST_SV
`define DMA350_TRIG_SRCCMD_DESBLOCK_TEST_SV

class dma350_trig_srccmd_desblock_test extends dma350_base_test;
  `uvm_component_utils(dma350_trig_srccmd_desblock_test)

  function new(string name = "dma350_trig_srccmd_desblock_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_trig_srccmd_desblock vseq = dma350_vseq_trig_srccmd_desblock::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_trig_srccmd_desblock_test

`endif // DMA350_TRIG_SRCCMD_DESBLOCK_TEST_SV
