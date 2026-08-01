//==============================================================================
// dma350_2d_wrap_srcy_gt_desy_test.sv
//   GROUP B - TRM 5.3.2.2 'SRCYSIZE > DESYSIZE'
//   Vung dich thap hon vung nguon (6 dong -> 3 dong).
//==============================================================================
`ifndef DMA350_2D_WRAP_SRCY_GT_DESY_TEST_SV
`define DMA350_2D_WRAP_SRCY_GT_DESY_TEST_SV

class dma350_2d_wrap_srcy_gt_desy_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_wrap_srcy_gt_desy_test)

  function new(string name = "dma350_2d_wrap_srcy_gt_desy_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_wrap_srcy_gt_desy vseq = dma350_vseq_2d_wrap_srcy_gt_desy::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_wrap_srcy_gt_desy_test

`endif // DMA350_2D_WRAP_SRCY_GT_DESY_TEST_SV
