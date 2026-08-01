//==============================================================================
// dma350_2d_corner_14_test.sv
//   GROUP C - TRM 5.3.2.1 Table 5-3 '2D corner cases', ID 14
//   SRCXSIZE=8 SRCYSIZE=1 DESXSIZE=8 DESYSIZE=4 -> Case 5 (1D to 2D)
//==============================================================================
`ifndef DMA350_2D_CORNER_14_TEST_SV
`define DMA350_2D_CORNER_14_TEST_SV

class dma350_2d_corner_14_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_corner_14_test)

  function new(string name = "dma350_2d_corner_14_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_corner_14 vseq = dma350_vseq_2d_corner_14::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_corner_14_test

`endif // DMA350_2D_CORNER_14_TEST_SV
