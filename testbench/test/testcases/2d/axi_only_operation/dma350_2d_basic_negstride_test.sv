//==============================================================================
// dma350_2d_basic_negstride_test.sv
//   GROUP A - TRM 5.3.1 (Figure 5-6, DESYADDRSTRIDE am)
//   Stride dich AM: DESADDR bat dau o dong cuoi va lui dan moi dong.
//==============================================================================
`ifndef DMA350_2D_BASIC_NEGSTRIDE_TEST_SV
`define DMA350_2D_BASIC_NEGSTRIDE_TEST_SV

class dma350_2d_basic_negstride_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_basic_negstride_test)

  function new(string name = "dma350_2d_basic_negstride_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_basic_negstride vseq = dma350_vseq_2d_basic_negstride::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_basic_negstride_test

`endif // DMA350_2D_BASIC_NEGSTRIDE_TEST_SV
