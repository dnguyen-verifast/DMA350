//==============================================================================
// dma350_2d_wrap_xy_test.sv
//   GROUP B - TRM 5.3.2.2, wrap ca hai chieu (tiling)
//   Nguon 4x2 duoc lat gach ra vung dich 8x4 (XTYPE=wrap, YTYPE=wrap).
//==============================================================================
`ifndef DMA350_2D_WRAP_XY_TEST_SV
`define DMA350_2D_WRAP_XY_TEST_SV

class dma350_2d_wrap_xy_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_wrap_xy_test)

  function new(string name = "dma350_2d_wrap_xy_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_wrap_xy vseq = dma350_vseq_2d_wrap_xy::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_wrap_xy_test

`endif // DMA350_2D_WRAP_XY_TEST_SV
