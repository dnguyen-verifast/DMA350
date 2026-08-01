//==============================================================================
// dma350_2d_wrap_x_eq_test.sv
//   GROUP B - TRM 5.3.2.2 'SRCXSIZE == DESXSIZE' + 'SRCYSIZE == DESYSIZE'
//   Kich thuoc bang nhau -> wrap khong co tac dung, la copy 2D thuong.
//==============================================================================
`ifndef DMA350_2D_WRAP_X_EQ_TEST_SV
`define DMA350_2D_WRAP_X_EQ_TEST_SV

class dma350_2d_wrap_x_eq_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_wrap_x_eq_test)

  function new(string name = "dma350_2d_wrap_x_eq_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_wrap_x_eq vseq = dma350_vseq_2d_wrap_x_eq::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_wrap_x_eq_test

`endif // DMA350_2D_WRAP_X_EQ_TEST_SV
