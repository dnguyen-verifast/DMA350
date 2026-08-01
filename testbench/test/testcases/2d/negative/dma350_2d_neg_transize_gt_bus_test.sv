//==============================================================================
// dma350_2d_neg_transize_gt_bus_test.sv
//   GROUP X (AM) - TRM 5.9.2.2 'TRANSIZE is set to be greater than the bus width'
//   TRANSIZE = 111 (1024-bit) vuot do rong bus tren mot lenh 2D.
//==============================================================================
`ifndef DMA350_2D_NEG_TRANSIZE_GT_BUS_TEST_SV
`define DMA350_2D_NEG_TRANSIZE_GT_BUS_TEST_SV

class dma350_2d_neg_transize_gt_bus_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_neg_transize_gt_bus_test)

  function new(string name = "dma350_2d_neg_transize_gt_bus_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_neg_transize_gt_bus vseq = dma350_vseq_2d_neg_transize_gt_bus::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_neg_transize_gt_bus_test

`endif // DMA350_2D_NEG_TRANSIZE_GT_BUS_TEST_SV
