//==============================================================================
// dma350_vseq_2d_corner_19.sv
//   GROUP C - TRM 5.3.2.1 Table 5-3 '2D corner cases', ID 19
//   SRCXSIZE=8 SRCYSIZE=4 DESXSIZE=8 DESYSIZE=4 -> Case 5 (2D to 2D)
//   Ky vong: hanh vi dung nhu cot Case cua Table 5-3.
//==============================================================================
`ifndef DMA350_VSEQ_2D_CORNER_19_SV
`define DMA350_VSEQ_2D_CORNER_19_SV

class dma350_vseq_2d_corner_19 extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_corner_19)

  function new(string name = "dma350_vseq_2d_corner_19");
    super.new(name);
    src_xsize = 8;
    src_ysize = 4;
    des_xsize = 8;
    des_ysize = 4;
    chk_src_drained = 1;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_corner_19

`endif // DMA350_VSEQ_2D_CORNER_19_SV
