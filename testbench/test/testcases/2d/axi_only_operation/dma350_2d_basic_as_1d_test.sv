//==============================================================================
// dma350_2d_basic_as_1d_test.sv
//   GROUP A - TRM 5.3.1 ('1D transfers can still be created ... setting YSIZE to 1')
//   May 2D chay lenh 1D: SRCYSIZE = DESYSIZE = 1, XSIZE = 32.
//==============================================================================
`ifndef DMA350_2D_BASIC_AS_1D_TEST_SV
`define DMA350_2D_BASIC_AS_1D_TEST_SV

class dma350_2d_basic_as_1d_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_basic_as_1d_test)

  function new(string name = "dma350_2d_basic_as_1d_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_basic_as_1d vseq = dma350_vseq_2d_basic_as_1d::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_basic_as_1d_test

`endif // DMA350_2D_BASIC_AS_1D_TEST_SV
