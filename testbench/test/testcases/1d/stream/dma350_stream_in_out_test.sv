//==============================================================================
// dma350_stream_in_out_test.sv
//   Stream mode (TRM 5.5) - kenh don CH0.
//   vseq: dma350_vseq_stream_in_out
//==============================================================================
`ifndef DMA350_STREAM_IN_OUT_TEST_SV
`define DMA350_STREAM_IN_OUT_TEST_SV

class dma350_stream_in_out_test extends dma350_base_test;
  `uvm_component_utils(dma350_stream_in_out_test)

  function new(string name = "dma350_stream_in_out_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_stream_in_out vseq = dma350_vseq_stream_in_out::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_stream_in_out_test

`endif // DMA350_STREAM_IN_OUT_TEST_SV
