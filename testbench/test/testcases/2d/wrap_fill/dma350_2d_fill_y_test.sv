//==============================================================================
// dma350_2d_fill_y_test.sv
//   GROUP B - TRM 5.3.2.2 'SRCYSIZE < DESYSIZE', YTYPE = fill
//   Het du lieu nguon (2 dong) thi cac dong dich con lai duoc do FILLVAL.
//==============================================================================
`ifndef DMA350_2D_FILL_Y_TEST_SV
`define DMA350_2D_FILL_Y_TEST_SV

class dma350_2d_fill_y_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_fill_y_test)

  function new(string name = "dma350_2d_fill_y_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_fill_y vseq = dma350_vseq_2d_fill_y::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_fill_y_test

`endif // DMA350_2D_FILL_Y_TEST_SV
