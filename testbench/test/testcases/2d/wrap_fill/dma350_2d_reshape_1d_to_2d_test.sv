//==============================================================================
// dma350_2d_reshape_1d_to_2d_test.sv
//   GROUP B - TRM 5.3.2.2 (XTYPE=continue cho phep chuyen 1D -> 2D)
//   Nguon la MOT dong dai (SRCYSIZE=1, 32 element), dich la khoi 8x4.
//==============================================================================
`ifndef DMA350_2D_RESHAPE_1D_TO_2D_TEST_SV
`define DMA350_2D_RESHAPE_1D_TO_2D_TEST_SV

class dma350_2d_reshape_1d_to_2d_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_reshape_1d_to_2d_test)

  function new(string name = "dma350_2d_reshape_1d_to_2d_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_reshape_1d_to_2d vseq = dma350_vseq_2d_reshape_1d_to_2d::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_reshape_1d_to_2d_test

`endif // DMA350_2D_RESHAPE_1D_TO_2D_TEST_SV
