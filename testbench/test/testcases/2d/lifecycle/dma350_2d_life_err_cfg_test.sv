//==============================================================================
// dma350_2d_life_err_cfg_test.sv
//   GROUP I - TRM 5.6.3 'Configuration errors' tren lenh 2D
//   TRANSIZE lon hon do rong bus (RTL: regval_err) tren mot lenh 2D hop le.
//==============================================================================
`ifndef DMA350_2D_LIFE_ERR_CFG_TEST_SV
`define DMA350_2D_LIFE_ERR_CFG_TEST_SV

class dma350_2d_life_err_cfg_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_life_err_cfg_test)

  function new(string name = "dma350_2d_life_err_cfg_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_life_err_cfg vseq = dma350_vseq_2d_life_err_cfg::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_life_err_cfg_test

`endif // DMA350_2D_LIFE_ERR_CFG_TEST_SV
