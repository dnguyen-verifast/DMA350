//==============================================================================
// dma350_vseq_2d_corner_18.sv
//   GROUP C - TRM 5.3.2.1 Table 5-3 '2D corner cases', ID 18
//   SRCXSIZE=8 SRCYSIZE=4 DESXSIZE=8 DESYSIZE=1 -> Case 5 (2D to 1D)
//   Ky vong: hanh vi dung nhu cot Case cua Table 5-3.
//==============================================================================
`ifndef DMA350_VSEQ_2D_CORNER_18_SV
`define DMA350_VSEQ_2D_CORNER_18_SV

class dma350_vseq_2d_corner_18 extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_corner_18)

  function new(string name = "dma350_vseq_2d_corner_18");
    super.new(name);
    src_xsize = 8;
    src_ysize = 4;
    des_xsize = 8;
    des_ysize = 1;
    ytype = YT_CONT;
  endfunction

endclass : dma350_vseq_2d_corner_18

`endif // DMA350_VSEQ_2D_CORNER_18_SV
