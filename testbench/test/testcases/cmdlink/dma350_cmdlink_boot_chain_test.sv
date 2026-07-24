//==============================================================================
// dma350_cmdlink_boot_chain_test.sv
//   Command linking (TRM 5.7) - kenh don CH0.
//   vseq: dma350_vseq_cmdlink_boot_chain
//==============================================================================
`ifndef DMA350_CMDLINK_BOOT_CHAIN_TEST_SV
`define DMA350_CMDLINK_BOOT_CHAIN_TEST_SV

class dma350_cmdlink_boot_chain_test extends dma350_base_test;
  `uvm_component_utils(dma350_cmdlink_boot_chain_test)

  function new(string name = "dma350_cmdlink_boot_chain_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_cmdlink_boot_chain vseq = dma350_vseq_cmdlink_boot_chain::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_cmdlink_boot_chain_test

`endif // DMA350_CMDLINK_BOOT_CHAIN_TEST_SV
