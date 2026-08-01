//==============================================================================
// dma350_2d_neg_trigsel_out_of_range_test.sv
//   GROUP X (AM) - TRM 5.9.2.2 'Non-existent trigger resource is selected'
//   SRCTRIGINSEL tro toi cong trigger vuot NUM_TRIGGER_IN tren lenh 2D.
//==============================================================================
`ifndef DMA350_2D_NEG_TRIGSEL_OUT_OF_RANGE_TEST_SV
`define DMA350_2D_NEG_TRIGSEL_OUT_OF_RANGE_TEST_SV

class dma350_2d_neg_trigsel_out_of_range_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_neg_trigsel_out_of_range_test)

  function new(string name = "dma350_2d_neg_trigsel_out_of_range_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_neg_trigsel_out_of_range vseq = dma350_vseq_2d_neg_trigsel_out_of_range::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_neg_trigsel_out_of_range_test

`endif // DMA350_2D_NEG_TRIGSEL_OUT_OF_RANGE_TEST_SV
