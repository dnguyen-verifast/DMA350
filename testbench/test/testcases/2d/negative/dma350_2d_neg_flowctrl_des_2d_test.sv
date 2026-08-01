//==============================================================================
// dma350_2d_neg_flowctrl_des_2d_test.sv
//   GROUP X (AM) - TRM 5.9.2.2, phia DICH dat flow-control trigger tren lenh 2D
//   DESTRIGINMODE = flow control trong khi DESYSIZE = 4 (> 1).
//==============================================================================
`ifndef DMA350_2D_NEG_FLOWCTRL_DES_2D_TEST_SV
`define DMA350_2D_NEG_FLOWCTRL_DES_2D_TEST_SV

class dma350_2d_neg_flowctrl_des_2d_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_neg_flowctrl_des_2d_test)

  function new(string name = "dma350_2d_neg_flowctrl_des_2d_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_neg_flowctrl_des_2d vseq = dma350_vseq_2d_neg_flowctrl_des_2d::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_neg_flowctrl_des_2d_test

`endif // DMA350_2D_NEG_FLOWCTRL_DES_2D_TEST_SV
