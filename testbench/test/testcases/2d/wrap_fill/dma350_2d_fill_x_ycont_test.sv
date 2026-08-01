//==============================================================================
// dma350_2d_fill_x_ycont_test.sv
//   GROUP B - TRM 5.3.2.2, XTYPE = fill ket hop YTYPE = continue
//   Moi dong dich (9 element) rong hon dong nguon (5) -> vien phai do FILLVAL,
//==============================================================================
`ifndef DMA350_2D_FILL_X_YCONT_TEST_SV
`define DMA350_2D_FILL_X_YCONT_TEST_SV

class dma350_2d_fill_x_ycont_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_fill_x_ycont_test)

  function new(string name = "dma350_2d_fill_x_ycont_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_fill_x_ycont vseq = dma350_vseq_2d_fill_x_ycont::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_fill_x_ycont_test

`endif // DMA350_2D_FILL_X_YCONT_TEST_SV
