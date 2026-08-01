//==============================================================================
// dma350_2d_neg_xtype_wrap_stream_test.sv
//   GROUP X (AM) - TRM Table 5-6 hang '2D Wrap / bat ky YTYPE -> No'
//   XTYPE = wrap tren lenh 2D co stream -> config error.
//==============================================================================
`ifndef DMA350_2D_NEG_XTYPE_WRAP_STREAM_TEST_SV
`define DMA350_2D_NEG_XTYPE_WRAP_STREAM_TEST_SV

class dma350_2d_neg_xtype_wrap_stream_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_neg_xtype_wrap_stream_test)

  function new(string name = "dma350_2d_neg_xtype_wrap_stream_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_neg_xtype_wrap_stream vseq = dma350_vseq_2d_neg_xtype_wrap_stream::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_neg_xtype_wrap_stream_test

`endif // DMA350_2D_NEG_XTYPE_WRAP_STREAM_TEST_SV
