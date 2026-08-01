//==============================================================================
// dma350_cmdlink_apb_example_test.sv
//   Command linking (TRM 5.7) - kenh don CH0, dung anh vi du co san cua package.
//   vseq: dma350_vseq_cmdlink_apb_example
//==============================================================================
`ifndef DMA350_CMDLINK_APB_EXAMPLE_TEST_SV
`define DMA350_CMDLINK_APB_EXAMPLE_TEST_SV

class dma350_cmdlink_apb_example_test extends dma350_base_test;
  `uvm_component_utils(dma350_cmdlink_apb_example_test)

  function new(string name = "dma350_cmdlink_apb_example_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_cmdlink_apb_example vseq = dma350_vseq_cmdlink_apb_example::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_cmdlink_apb_example_test

`endif // DMA350_CMDLINK_APB_EXAMPLE_TEST_SV
