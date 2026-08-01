//==============================================================================
// dma350_1d_single_src_gt_des_cont_test.sv
//   TRM 5.2.2 -- SRCXSIZE > DESXSIZE  | XTYPE = continue
//   Destination khong du cho -> copy dung khi des day. Du lieu thua bi drop trong DMAC, KHONG ghi de.
//==============================================================================
`ifndef DMA350_1D_SINGLE_SRC_GT_DES_CONT_TEST_SV
`define DMA350_1D_SINGLE_SRC_GT_DES_CONT_TEST_SV

class dma350_1d_single_src_gt_des_cont_test extends dma350_base_test;
  `uvm_component_utils(dma350_1d_single_src_gt_des_cont_test)

  function new(string name = "dma350_1d_single_src_gt_des_cont_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_1d_single_src_gt_des_cont vseq = dma350_vseq_1d_single_src_gt_des_cont::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_1d_single_src_gt_des_cont_test

`endif // DMA350_1D_SINGLE_SRC_GT_DES_CONT_TEST_SV
