//==============================================================================
// dma350_2d_trig_hw_cmd_src_test.sv
//   GROUP F - TRM 5.4.1.1 'Trigger input command mode' (phia nguon) tren 2D
//   Trigger phan cung tren cong TI0 khoi dong toan bo lenh 2D.
//==============================================================================
`ifndef DMA350_2D_TRIG_HW_CMD_SRC_TEST_SV
`define DMA350_2D_TRIG_HW_CMD_SRC_TEST_SV

class dma350_2d_trig_hw_cmd_src_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_trig_hw_cmd_src_test)

  function new(string name = "dma350_2d_trig_hw_cmd_src_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_trig_hw_cmd_src vseq = dma350_vseq_2d_trig_hw_cmd_src::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_trig_hw_cmd_src_test

`endif // DMA350_2D_TRIG_HW_CMD_SRC_TEST_SV
