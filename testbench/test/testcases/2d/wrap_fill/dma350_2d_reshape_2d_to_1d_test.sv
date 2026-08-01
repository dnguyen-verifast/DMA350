//==============================================================================
// dma350_2d_reshape_2d_to_1d_test.sv
//   GROUP B - TRM 5.3.2.2 (XTYPE=continue cho phep chuyen 2D -> 1D)
//   Nguon la khoi 8x4, dich la MOT dong dai (DESYSIZE=1, 32 element).
//==============================================================================
`ifndef DMA350_2D_RESHAPE_2D_TO_1D_TEST_SV
`define DMA350_2D_RESHAPE_2D_TO_1D_TEST_SV

class dma350_2d_reshape_2d_to_1d_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_reshape_2d_to_1d_test)

  function new(string name = "dma350_2d_reshape_2d_to_1d_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_reshape_2d_to_1d vseq = dma350_vseq_2d_reshape_2d_to_1d::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_reshape_2d_to_1d_test

`endif // DMA350_2D_RESHAPE_2D_TO_1D_TEST_SV
