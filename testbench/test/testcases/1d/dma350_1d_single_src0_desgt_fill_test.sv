//==============================================================================
// dma350_1d_single_src0_desgt_fill_test.sv
//   TRM 5.2.2 -- SRCXSIZE == 0, DESXSIZE > 0  | XTYPE = fill
//   Destination duoc dien fill value -> CHI co write (DESXSIZE write).
//==============================================================================
`ifndef DMA350_1D_SINGLE_SRC0_DESGT_FILL_TEST_SV
`define DMA350_1D_SINGLE_SRC0_DESGT_FILL_TEST_SV

class dma350_1d_single_src0_desgt_fill_test extends dma350_base_test;
  `uvm_component_utils(dma350_1d_single_src0_desgt_fill_test)

  function new(string name = "dma350_1d_single_src0_desgt_fill_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_1d_single_src0_desgt_fill vseq = dma350_vseq_1d_single_src0_desgt_fill::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_1d_single_src0_desgt_fill_test

`endif // DMA350_1D_SINGLE_SRC0_DESGT_FILL_TEST_SV
