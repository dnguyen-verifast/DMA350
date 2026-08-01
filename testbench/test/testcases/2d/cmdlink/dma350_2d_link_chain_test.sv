//==============================================================================
// dma350_2d_link_chain_test.sv
//   GROUP H - TRM 5.7.1 'Command structure', chuoi nhieu lenh 2D
//   Lenh #0 cau hinh qua APB (2D), link toi 2 descriptor 2D nap qua AXI.
//==============================================================================
`ifndef DMA350_2D_LINK_CHAIN_TEST_SV
`define DMA350_2D_LINK_CHAIN_TEST_SV

class dma350_2d_link_chain_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_link_chain_test)

  function new(string name = "dma350_2d_link_chain_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_link_chain vseq = dma350_vseq_2d_link_chain::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_link_chain_test

`endif // DMA350_2D_LINK_CHAIN_TEST_SV
