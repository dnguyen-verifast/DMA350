//==============================================================================
// dma350_cmdlink_apb_addr_size_test.sv
//   Command linking (TRM 5.7) - kenh don CH0.
//   vseq: dma350_vseq_cmdlink_apb_addr_size
//==============================================================================
`ifndef DMA350_CMDLINK_APB_ADDR_SIZE_TEST_SV
`define DMA350_CMDLINK_APB_ADDR_SIZE_TEST_SV

class dma350_cmdlink_apb_addr_size_test extends dma350_base_test;
  `uvm_component_utils(dma350_cmdlink_apb_addr_size_test)

  function new(string name = "dma350_cmdlink_apb_addr_size_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_cmdlink_apb_addr_size vseq = dma350_vseq_cmdlink_apb_addr_size::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_cmdlink_apb_addr_size_test

`endif // DMA350_CMDLINK_APB_ADDR_SIZE_TEST_SV
