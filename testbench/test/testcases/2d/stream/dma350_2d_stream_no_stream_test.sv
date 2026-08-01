//==============================================================================
// dma350_2d_stream_no_stream_test.sv
//   GROUP G - TRM Table 5-6, moc so sanh: 2D KHONG dung stream
//   USESTREAM = 0 -> copy 2D mem-to-mem thuong tren cung cau hinh hinh hoc.
//==============================================================================
`ifndef DMA350_2D_STREAM_NO_STREAM_TEST_SV
`define DMA350_2D_STREAM_NO_STREAM_TEST_SV

class dma350_2d_stream_no_stream_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_stream_no_stream_test)

  function new(string name = "dma350_2d_stream_no_stream_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_stream_no_stream vseq = dma350_vseq_2d_stream_no_stream::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_stream_no_stream_test

`endif // DMA350_2D_STREAM_NO_STREAM_TEST_SV
