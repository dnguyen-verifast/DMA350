//==============================================================================
// dma350_2d_stream_early_tlast_test.sv
//   GROUP G - TRM 5.5.1 'When tlast is received while DESXSIZE ... greater than 0'
//   str_in ket thuc SOM (it beat hon vung dich 2D can).
//==============================================================================
`ifndef DMA350_2D_STREAM_EARLY_TLAST_TEST_SV
`define DMA350_2D_STREAM_EARLY_TLAST_TEST_SV

class dma350_2d_stream_early_tlast_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_stream_early_tlast_test)

  function new(string name = "dma350_2d_stream_early_tlast_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_stream_early_tlast vseq = dma350_vseq_2d_stream_early_tlast::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_stream_early_tlast_test

`endif // DMA350_2D_STREAM_EARLY_TLAST_TEST_SV
