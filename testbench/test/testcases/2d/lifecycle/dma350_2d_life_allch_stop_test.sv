//==============================================================================
// dma350_2d_life_allch_stop_test.sv
//   GROUP I - TRM 4.8.2 'Stop and pause control' (all-channel) tren 2D
//   Dung TAT CA channel non-secure qua NSEC_CTRL.ALLCHSTOP trong khi CH0 chay 2D.
//==============================================================================
`ifndef DMA350_2D_LIFE_ALLCH_STOP_TEST_SV
`define DMA350_2D_LIFE_ALLCH_STOP_TEST_SV

class dma350_2d_life_allch_stop_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_life_allch_stop_test)

  function new(string name = "dma350_2d_life_allch_stop_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_life_allch_stop vseq = dma350_vseq_2d_life_allch_stop::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_life_allch_stop_test

`endif // DMA350_2D_LIFE_ALLCH_STOP_TEST_SV
