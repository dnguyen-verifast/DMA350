//==============================================================================
// dma350_2d_sec_priv_test.sv
//   GROUP K - TRM 5.10 / 6.5.1.11-12, thuoc tinh truy cap tren lenh 2D
//   Non-secure + Privileged.
//==============================================================================
`ifndef DMA350_2D_SEC_PRIV_TEST_SV
`define DMA350_2D_SEC_PRIV_TEST_SV

class dma350_2d_sec_priv_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_sec_priv_test)

  function new(string name = "dma350_2d_sec_priv_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_sec_priv vseq = dma350_vseq_2d_sec_priv::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_sec_priv_test

`endif // DMA350_2D_SEC_PRIV_TEST_SV
