//==============================================================================
// dma350_trig_srcflow_last_block_test.sv
//   SOURCE = FLOW CONTROL mode, request type = LAST_BLOCK (cong TI0); DES khong dung trigger
//   Flow-control mode + LAST_BLOCK: block cuoi (co the ngan hon BLKSIZE) -> LAST_OKAY.
//==============================================================================
`ifndef DMA350_TRIG_SRCFLOW_LAST_BLOCK_TEST_SV
`define DMA350_TRIG_SRCFLOW_LAST_BLOCK_TEST_SV

class dma350_trig_srcflow_last_block_test extends dma350_base_test;
  `uvm_component_utils(dma350_trig_srcflow_last_block_test)

  function new(string name = "dma350_trig_srcflow_last_block_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_trig_srcflow_last_block vseq = dma350_vseq_trig_srcflow_last_block::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_trig_srcflow_last_block_test

`endif // DMA350_TRIG_SRCFLOW_LAST_BLOCK_TEST_SV
