//==============================================================================
// dma350_2d_arb_prio_test.sv
//   GROUP L - TRM 5.8.2 'Arbitration scheme' (fixed priority) tren 2D
//   CH1 dat CHPRIO cao hon CH0 (CH_CTRL[7:4]) -> CH1 duoc uu tien tren bus.
//==============================================================================
`ifndef DMA350_2D_ARB_PRIO_TEST_SV
`define DMA350_2D_ARB_PRIO_TEST_SV

class dma350_2d_arb_prio_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_arb_prio_test)

  function new(string name = "dma350_2d_arb_prio_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_arb_prio vseq = dma350_vseq_2d_arb_prio::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_arb_prio_test

`endif // DMA350_2D_ARB_PRIO_TEST_SV
