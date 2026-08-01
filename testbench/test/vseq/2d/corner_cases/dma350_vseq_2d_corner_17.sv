//==============================================================================
// dma350_vseq_2d_corner_17.sv
//   GROUP C - TRM 5.3.2.1 Table 5-3 '2D corner cases', ID 17
//   SRCXSIZE=8 SRCYSIZE=4 DESXSIZE=8 DESYSIZE=0 -> Case 3 (Read only)
//   Ky vong: hanh vi dung nhu cot Case cua Table 5-3.
//==============================================================================
`ifndef DMA350_VSEQ_2D_CORNER_17_SV
`define DMA350_VSEQ_2D_CORNER_17_SV

class dma350_vseq_2d_corner_17 extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_corner_17)

  function new(string name = "dma350_vseq_2d_corner_17");
    super.new(name);
    src_xsize = 8;
    src_ysize = 4;
    des_xsize = 8;
    des_ysize = 0;
  endfunction

endclass : dma350_vseq_2d_corner_17

`endif // DMA350_VSEQ_2D_CORNER_17_SV
