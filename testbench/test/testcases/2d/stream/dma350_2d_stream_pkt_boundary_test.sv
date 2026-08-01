//==============================================================================
// dma350_2d_stream_pkt_boundary_test.sv
//   GROUP G - TRM 5.5.2 'Packet boundaries on stream out interface' cho 2D
//   Khung 2D nhieu dong nhung stream out chi duoc coi la MOT packet.
//==============================================================================
`ifndef DMA350_2D_STREAM_PKT_BOUNDARY_TEST_SV
`define DMA350_2D_STREAM_PKT_BOUNDARY_TEST_SV

class dma350_2d_stream_pkt_boundary_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_stream_pkt_boundary_test)

  function new(string name = "dma350_2d_stream_pkt_boundary_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_stream_pkt_boundary vseq = dma350_vseq_2d_stream_pkt_boundary::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_stream_pkt_boundary_test

`endif // DMA350_2D_STREAM_PKT_BOUNDARY_TEST_SV
