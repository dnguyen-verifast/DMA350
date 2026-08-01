//==============================================================================
// dma350_2d_arb_2d_vs_1d_test.sv
//   GROUP L - TRM 5.8.1 'Arbitration requests', tron 2D va 1D
//   CH0 chay khung 2D dai, CH1 chay copy 1D ngan cung luc.
//==============================================================================
`ifndef DMA350_2D_ARB_2D_VS_1D_TEST_SV
`define DMA350_2D_ARB_2D_VS_1D_TEST_SV

class dma350_2d_arb_2d_vs_1d_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_arb_2d_vs_1d_test)

  function new(string name = "dma350_2d_arb_2d_vs_1d_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_arb_2d_vs_1d vseq = dma350_vseq_2d_arb_2d_vs_1d::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_arb_2d_vs_1d_test

`endif // DMA350_2D_ARB_2D_VS_1D_TEST_SV
