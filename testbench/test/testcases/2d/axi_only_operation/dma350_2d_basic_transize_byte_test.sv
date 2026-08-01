//==============================================================================
// dma350_2d_basic_transize_byte_test.sv
//   GROUP A - TRM 5.3.1 + 6.5.1.4 TRANSIZE
//   2D voi TRANSIZE = byte (000): dong 8 element = 8 byte, stride 0x10.
//==============================================================================
`ifndef DMA350_2D_BASIC_TRANSIZE_BYTE_TEST_SV
`define DMA350_2D_BASIC_TRANSIZE_BYTE_TEST_SV

class dma350_2d_basic_transize_byte_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_basic_transize_byte_test)

  function new(string name = "dma350_2d_basic_transize_byte_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_basic_transize_byte vseq = dma350_vseq_2d_basic_transize_byte::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_basic_transize_byte_test

`endif // DMA350_2D_BASIC_TRANSIZE_BYTE_TEST_SV
