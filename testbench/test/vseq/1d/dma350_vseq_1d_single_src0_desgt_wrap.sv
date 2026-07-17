//==============================================================================
// dma350_vseq_1d_single_src0_desgt_wrap.sv
//   TRM 5.2.2 (List of cases for 1D WRAP) -- SRCXSIZE == 0, DESXSIZE > 0
//   XTYPE = wrap
//
//   Ky vong: Nothing happens: khong co read hay write nao xay ra.
//==============================================================================
`ifndef DMA350_VSEQ_1D_SINGLE_SRC0_DESGT_WRAP_SV
`define DMA350_VSEQ_1D_SINGLE_SRC0_DESGT_WRAP_SV

class dma350_vseq_1d_single_src0_desgt_wrap extends dma350_vseq_1d_single_base;
  `uvm_object_utils(dma350_vseq_1d_single_src0_desgt_wrap)

  function new(string name = "dma350_vseq_1d_single_src0_desgt_wrap");
    super.new(name);
    src_xsize       = 0;
    des_xsize       = 16;
    src_xaddrinc    = 1;
    des_xaddrinc    = 1;
    xtype           = XT_WRAP;
    expect_idle     = 1;
    chk_src_drained = 0;
    chk_des_drained = 0;
  endfunction

  virtual task body();
    super.body();   // POR + responder AXI5/AXIS
    run_1d(0);
  endtask

endclass : dma350_vseq_1d_single_src0_desgt_wrap

`endif // DMA350_VSEQ_1D_SINGLE_SRC0_DESGT_WRAP_SV
