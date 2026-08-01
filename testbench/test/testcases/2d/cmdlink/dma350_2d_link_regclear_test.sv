//==============================================================================
// dma350_2d_link_regclear_test.sv
//   GROUP H - TRM 5.7.1 'REGCLEAR' tren chuoi 2D
//   Descriptor dat bit REGCLEAR -> xoa toan bo thanh ghi 2D truoc khi nap gia tri moi.
//==============================================================================
`ifndef DMA350_2D_LINK_REGCLEAR_TEST_SV
`define DMA350_2D_LINK_REGCLEAR_TEST_SV

class dma350_2d_link_regclear_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_link_regclear_test)

  function new(string name = "dma350_2d_link_regclear_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_link_regclear vseq = dma350_vseq_2d_link_regclear::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_link_regclear_test

`endif // DMA350_2D_LINK_REGCLEAR_TEST_SV
