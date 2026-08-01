//==============================================================================
// dma350_2d_basic_large_frame_test.sv
//   GROUP A - TRM 5.3.1, khung lon de sinh nhieu burst / nhieu dong
//   Khung 16 element x 16 dong, stride 0x80 -> 16 lan start_line.
//==============================================================================
`ifndef DMA350_2D_BASIC_LARGE_FRAME_TEST_SV
`define DMA350_2D_BASIC_LARGE_FRAME_TEST_SV

class dma350_2d_basic_large_frame_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_basic_large_frame_test)

  function new(string name = "dma350_2d_basic_large_frame_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_basic_large_frame vseq = dma350_vseq_2d_basic_large_frame::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_basic_large_frame_test

`endif // DMA350_2D_BASIC_LARGE_FRAME_TEST_SV
