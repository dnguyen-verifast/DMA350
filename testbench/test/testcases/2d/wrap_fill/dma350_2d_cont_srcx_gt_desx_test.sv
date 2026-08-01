//==============================================================================
// dma350_2d_cont_srcx_gt_desx_test.sv
//   GROUP B - TRM 5.3.2.2 'SRCXSIZE > DESXSIZE' + XTYPE = continue
//   Dong nguon rong hon dong dich -> phan du chay tiep sang dong dich ke tiep.
//==============================================================================
`ifndef DMA350_2D_CONT_SRCX_GT_DESX_TEST_SV
`define DMA350_2D_CONT_SRCX_GT_DESX_TEST_SV

class dma350_2d_cont_srcx_gt_desx_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_cont_srcx_gt_desx_test)

  function new(string name = "dma350_2d_cont_srcx_gt_desx_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_cont_srcx_gt_desx vseq = dma350_vseq_2d_cont_srcx_gt_desx::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_cont_srcx_gt_desx_test

`endif // DMA350_2D_CONT_SRCX_GT_DESX_TEST_SV
