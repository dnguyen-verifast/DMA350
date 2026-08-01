//==============================================================================
// dma350_2d_life_done_pause_test.sv
//   GROUP I - TRM 6.5.1.4 DONEPAUSEEN tren lenh 2D
//   DONEPAUSEEN = 1: khi STAT_DONE len thi channel tu dong vao trang thai paused.
//==============================================================================
`ifndef DMA350_2D_LIFE_DONE_PAUSE_TEST_SV
`define DMA350_2D_LIFE_DONE_PAUSE_TEST_SV

class dma350_2d_life_done_pause_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_life_done_pause_test)

  function new(string name = "dma350_2d_life_done_pause_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_life_done_pause vseq = dma350_vseq_2d_life_done_pause::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_life_done_pause_test

`endif // DMA350_2D_LIFE_DONE_PAUSE_TEST_SV
