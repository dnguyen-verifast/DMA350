//==============================================================================
// dma350_vseq_2d_corner_14.sv
//   GROUP C - TRM 5.3.2.1 Table 5-3 '2D corner cases', ID 14
//   SRCXSIZE=8 SRCYSIZE=1 DESXSIZE=8 DESYSIZE=4 -> Case 5 (1D to 2D)
//   Ky vong: hanh vi dung nhu cot Case cua Table 5-3.
//==============================================================================
`ifndef DMA350_VSEQ_2D_CORNER_14_SV
`define DMA350_VSEQ_2D_CORNER_14_SV

class dma350_vseq_2d_corner_14 extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_corner_14)

  function new(string name = "dma350_vseq_2d_corner_14");
    super.new(name);
    src_xsize = 8;
    src_ysize = 1;
    des_xsize = 8;
    des_ysize = 4;
    ytype = YT_CONT;
  endfunction

endclass : dma350_vseq_2d_corner_14

`endif // DMA350_VSEQ_2D_CORNER_14_SV
