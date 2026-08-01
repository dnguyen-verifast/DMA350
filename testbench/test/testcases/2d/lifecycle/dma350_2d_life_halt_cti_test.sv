//==============================================================================
// dma350_2d_life_halt_cti_test.sv
//   GROUP I - TRM 5.9.3 'Halting and restarting the DMA with CTI' tren 2D
//   halt_req qua Cross Trigger Interface giua khung 2D roi restart_req.
//==============================================================================
`ifndef DMA350_2D_LIFE_HALT_CTI_TEST_SV
`define DMA350_2D_LIFE_HALT_CTI_TEST_SV

class dma350_2d_life_halt_cti_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_life_halt_cti_test)

  function new(string name = "dma350_2d_life_halt_cti_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_life_halt_cti vseq = dma350_vseq_2d_life_halt_cti::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_life_halt_cti_test

`endif // DMA350_2D_LIFE_HALT_CTI_TEST_SV
