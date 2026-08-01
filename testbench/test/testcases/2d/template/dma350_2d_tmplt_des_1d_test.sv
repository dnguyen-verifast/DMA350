//==============================================================================
// dma350_2d_tmplt_des_1d_test.sv
//   GROUP E - TRM 5.3.3 'Templated transfers' (phia dich)
//   Template dich rai khoi lien tuc ra cac vi tri thua thot.
//==============================================================================
`ifndef DMA350_2D_TMPLT_DES_1D_TEST_SV
`define DMA350_2D_TMPLT_DES_1D_TEST_SV

class dma350_2d_tmplt_des_1d_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_tmplt_des_1d_test)

  function new(string name = "dma350_2d_tmplt_des_1d_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_tmplt_des_1d vseq = dma350_vseq_2d_tmplt_des_1d::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_tmplt_des_1d_test

`endif // DMA350_2D_TMPLT_DES_1D_TEST_SV
