//==============================================================================
// dma350_2d_reshape_same_area_test.sv
//   GROUP B - TRM 5.3.2.2 (truong hop dac biet SX*SY == DX*DY)
//   Nguon 9x8 va dich 8x9: cung dien tich nhung khac hinh dang.
//==============================================================================
`ifndef DMA350_2D_RESHAPE_SAME_AREA_TEST_SV
`define DMA350_2D_RESHAPE_SAME_AREA_TEST_SV

class dma350_2d_reshape_same_area_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_reshape_same_area_test)

  function new(string name = "dma350_2d_reshape_same_area_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_reshape_same_area vseq = dma350_vseq_2d_reshape_same_area::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_reshape_same_area_test

`endif // DMA350_2D_RESHAPE_SAME_AREA_TEST_SV
