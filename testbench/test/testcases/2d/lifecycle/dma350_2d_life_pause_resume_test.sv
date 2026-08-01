//==============================================================================
// dma350_2d_life_pause_resume_test.sv
//   GROUP I - TRM 5.6 'Paused state' tren lenh 2D dai
//   PAUSECMD giua chung -> STAT_PAUSED -> RESUMECMD -> chay tiep den DONE.
//==============================================================================
`ifndef DMA350_2D_LIFE_PAUSE_RESUME_TEST_SV
`define DMA350_2D_LIFE_PAUSE_RESUME_TEST_SV

class dma350_2d_life_pause_resume_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_life_pause_resume_test)

  function new(string name = "dma350_2d_life_pause_resume_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_life_pause_resume vseq = dma350_vseq_2d_life_pause_resume::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_life_pause_resume_test

`endif // DMA350_2D_LIFE_PAUSE_RESUME_TEST_SV
