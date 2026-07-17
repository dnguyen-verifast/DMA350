//==============================================================================
// dma350_1d_single_src_lt_des_wrap_test.sv
//   TRM 5.2.2 -- SRCXSIZE < DESXSIZE  | XTYPE = wrap
//   Het source -> con tro source quay ve dia chi dau, doc lai source nhieu lan. Tong DESXSIZE read va DESXSIZE write. LUU Y: khong the dung SRCXSIZE/SRCADDR de suy so read da thuc hien.
//==============================================================================
`ifndef DMA350_1D_SINGLE_SRC_LT_DES_WRAP_TEST_SV
`define DMA350_1D_SINGLE_SRC_LT_DES_WRAP_TEST_SV

class dma350_1d_single_src_lt_des_wrap_test extends dma350_base_test;
  `uvm_component_utils(dma350_1d_single_src_lt_des_wrap_test)

  function new(string name = "dma350_1d_single_src_lt_des_wrap_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_1d_single_src_lt_des_wrap vseq = dma350_vseq_1d_single_src_lt_des_wrap::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_1d_single_src_lt_des_wrap_test

`endif // DMA350_1D_SINGLE_SRC_LT_DES_WRAP_TEST_SV
