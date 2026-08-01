//==============================================================================
// dma350_2d_stream_cont_fill_test.sv
//   GROUP G - TRM Table 5-6 hang '2D Continue/Fill -> Yes'
//   Sau khi nhan TLAST, phan con lai cua vung dich duoc do FILLVAL.
//==============================================================================
`ifndef DMA350_2D_STREAM_CONT_FILL_TEST_SV
`define DMA350_2D_STREAM_CONT_FILL_TEST_SV

class dma350_2d_stream_cont_fill_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_stream_cont_fill_test)

  function new(string name = "dma350_2d_stream_cont_fill_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_stream_cont_fill vseq = dma350_vseq_2d_stream_cont_fill::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_stream_cont_fill_test

`endif // DMA350_2D_STREAM_CONT_FILL_TEST_SV
