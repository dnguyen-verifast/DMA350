//==============================================================================
// dma350_2d_stream_cont_cont_test.sv
//   GROUP G - TRM Table 5-6 hang '2D Continue/Continue -> Yes'
//   To hop DUOC PHEP ro rang trong bang: XTYPE = Continue, YTYPE = Continue.
//==============================================================================
`ifndef DMA350_2D_STREAM_CONT_CONT_TEST_SV
`define DMA350_2D_STREAM_CONT_CONT_TEST_SV

class dma350_2d_stream_cont_cont_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_stream_cont_cont_test)

  function new(string name = "dma350_2d_stream_cont_cont_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_stream_cont_cont vseq = dma350_vseq_2d_stream_cont_cont::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_stream_cont_cont_test

`endif // DMA350_2D_STREAM_CONT_CONT_TEST_SV
