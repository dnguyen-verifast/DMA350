//==============================================================================
// dma350_vseq_2d_corner_13.sv
//   GROUP C - TRM 5.3.2.1 Table 5-3 '2D corner cases', ID 13
//   SRCXSIZE=8 SRCYSIZE=1 DESXSIZE=8 DESYSIZE=1 -> Case 4 (1D to 1D)
//   Ky vong: hanh vi dung nhu cot Case cua Table 5-3.
//==============================================================================
`ifndef DMA350_VSEQ_2D_CORNER_13_SV
`define DMA350_VSEQ_2D_CORNER_13_SV

class dma350_vseq_2d_corner_13 extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_corner_13)

  function new(string name = "dma350_vseq_2d_corner_13");
    super.new(name);
    src_xsize = 8;
    src_ysize = 1;
    des_xsize = 8;
    des_ysize = 1;
    chk_src_drained = 1;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_corner_13

`endif // DMA350_VSEQ_2D_CORNER_13_SV
