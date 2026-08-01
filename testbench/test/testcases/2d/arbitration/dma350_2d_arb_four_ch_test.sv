//==============================================================================
// dma350_2d_arb_four_ch_test.sv
//   GROUP L - TRM 5.8.2, bon channel cung chay 2D
//   CH0..CH3 moi channel mot khung 2D tren vung nho rieng.
//==============================================================================
`ifndef DMA350_2D_ARB_FOUR_CH_TEST_SV
`define DMA350_2D_ARB_FOUR_CH_TEST_SV

class dma350_2d_arb_four_ch_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_arb_four_ch_test)

  function new(string name = "dma350_2d_arb_four_ch_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_arb_four_ch vseq = dma350_vseq_2d_arb_four_ch::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_arb_four_ch_test

`endif // DMA350_2D_ARB_FOUR_CH_TEST_SV
