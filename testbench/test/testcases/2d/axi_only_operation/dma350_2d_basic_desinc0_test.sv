//==============================================================================
// dma350_2d_basic_desinc0_test.sv
//   GROUP A - TRM 5.3.1 (Figure 5-6: DESXADDRINC = 0 -> ghi vao FIFO)
//   Dich la mot FIFO: DESXADDRINC = 0, moi element trong dong ghi cung dia chi;
//==============================================================================
`ifndef DMA350_2D_BASIC_DESINC0_TEST_SV
`define DMA350_2D_BASIC_DESINC0_TEST_SV

class dma350_2d_basic_desinc0_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_basic_desinc0_test)

  function new(string name = "dma350_2d_basic_desinc0_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_basic_desinc0 vseq = dma350_vseq_2d_basic_desinc0::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_basic_desinc0_test

`endif // DMA350_2D_BASIC_DESINC0_TEST_SV
