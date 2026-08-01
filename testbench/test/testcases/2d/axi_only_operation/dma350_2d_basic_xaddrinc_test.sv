//==============================================================================
// dma350_2d_basic_xaddrinc_test.sv
//   GROUP A - TRM 5.3.1 (Figure 5-6 '2D transfer with increments')
//   Doc nguon co gap trong dong: SRCXADDRINC = 2 -> chi lay 1 element trong 2.
//==============================================================================
`ifndef DMA350_2D_BASIC_XADDRINC_TEST_SV
`define DMA350_2D_BASIC_XADDRINC_TEST_SV

class dma350_2d_basic_xaddrinc_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_basic_xaddrinc_test)

  function new(string name = "dma350_2d_basic_xaddrinc_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_basic_xaddrinc vseq = dma350_vseq_2d_basic_xaddrinc::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_basic_xaddrinc_test

`endif // DMA350_2D_BASIC_XADDRINC_TEST_SV
