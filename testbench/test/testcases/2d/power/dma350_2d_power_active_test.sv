//==============================================================================
// dma350_2d_power_active_test.sv
//   GROUP J - TRM 5.9.1, moc so sanh: khung 2D chay o trang thai ON day du
//   Khong co yeu cau P/Q-Channel nao trong luc chay.
//==============================================================================
`ifndef DMA350_2D_POWER_ACTIVE_TEST_SV
`define DMA350_2D_POWER_ACTIVE_TEST_SV

class dma350_2d_power_active_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_power_active_test)

  function new(string name = "dma350_2d_power_active_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_power_active vseq = dma350_vseq_2d_power_active::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_power_active_test

`endif // DMA350_2D_POWER_ACTIVE_TEST_SV
