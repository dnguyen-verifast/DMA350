//==============================================================================
// dma350_2d_stream_in_only_test.sv
//   GROUP G - TRM 5.5.1 + Table 5-6, 'Stream in only' tren lenh 2D
//   Vung dich 2D duoc do bang du lieu den tu str_in; khong doc AXI (SRCXSIZE = 0).
//==============================================================================
`ifndef DMA350_2D_STREAM_IN_ONLY_TEST_SV
`define DMA350_2D_STREAM_IN_ONLY_TEST_SV

class dma350_2d_stream_in_only_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_stream_in_only_test)

  function new(string name = "dma350_2d_stream_in_only_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_stream_in_only vseq = dma350_vseq_2d_stream_in_only::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_stream_in_only_test

`endif // DMA350_2D_STREAM_IN_ONLY_TEST_SV
