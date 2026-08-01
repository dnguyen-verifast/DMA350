//==============================================================================
// dma350_2d_link_stride_update_test.sv
//   GROUP H - TRM Table 5-12 bit 13 (HDR_YADDRSTRIDE) tren command link
//   Chuoi 2 lenh, moi lenh doi stride (co ca stride AM) ma khong doi gi khac.
//==============================================================================
`ifndef DMA350_2D_LINK_STRIDE_UPDATE_TEST_SV
`define DMA350_2D_LINK_STRIDE_UPDATE_TEST_SV

class dma350_2d_link_stride_update_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_link_stride_update_test)

  function new(string name = "dma350_2d_link_stride_update_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_link_stride_update vseq = dma350_vseq_2d_link_stride_update::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_link_stride_update_test

`endif // DMA350_2D_LINK_STRIDE_UPDATE_TEST_SV
