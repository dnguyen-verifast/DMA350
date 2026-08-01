//==============================================================================
// dma350_2d_stream_in_out_test.sv
//   GROUP G - TRM 5.5 + Table 5-6, stream hai chieu tren lenh 2D
//   Doc AXI -> str_out, engine ngoai xu ly, str_in -> ghi AXI, tat ca theo hinh 2D.
//==============================================================================
`ifndef DMA350_2D_STREAM_IN_OUT_TEST_SV
`define DMA350_2D_STREAM_IN_OUT_TEST_SV

class dma350_2d_stream_in_out_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_stream_in_out_test)

  function new(string name = "dma350_2d_stream_in_out_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_stream_in_out vseq = dma350_vseq_2d_stream_in_out::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_stream_in_out_test

`endif // DMA350_2D_STREAM_IN_OUT_TEST_SV
