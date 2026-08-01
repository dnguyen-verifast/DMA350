//==============================================================================
// dma350_2d_xform_mirror_y_test.sv
//   GROUP D - TRM 5.3.1 Figure 5-7 'Mirroring' (lat doc)
//   DESYADDRSTRIDE am va DESADDR tro toi DONG CUOI cua vung dich.
//==============================================================================
`ifndef DMA350_2D_XFORM_MIRROR_Y_TEST_SV
`define DMA350_2D_XFORM_MIRROR_Y_TEST_SV

class dma350_2d_xform_mirror_y_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_xform_mirror_y_test)

  function new(string name = "dma350_2d_xform_mirror_y_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_xform_mirror_y vseq = dma350_vseq_2d_xform_mirror_y::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_xform_mirror_y_test

`endif // DMA350_2D_XFORM_MIRROR_Y_TEST_SV
