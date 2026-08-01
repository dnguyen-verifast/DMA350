//==============================================================================
// dma350_2d_link_ysize_update_test.sv
//   GROUP H - TRM Table 5-12 bit 15 (HDR_YSIZE) tren command link
//   Chuoi 3 lenh, MOI lenh chi doi CH_YSIZE (so dong) va DESADDR.
//==============================================================================
`ifndef DMA350_2D_LINK_YSIZE_UPDATE_TEST_SV
`define DMA350_2D_LINK_YSIZE_UPDATE_TEST_SV

class dma350_2d_link_ysize_update_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_link_ysize_update_test)

  function new(string name = "dma350_2d_link_ysize_update_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_link_ysize_update vseq = dma350_vseq_2d_link_ysize_update::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_link_ysize_update_test

`endif // DMA350_2D_LINK_YSIZE_UPDATE_TEST_SV
