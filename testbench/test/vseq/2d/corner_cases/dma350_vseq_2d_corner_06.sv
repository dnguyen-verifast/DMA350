//==============================================================================
// dma350_vseq_2d_corner_06.sv
//   GROUP C - TRM 5.3.2.1 Table 5-3 '2D corner cases', ID 6
//   SRCXSIZE=0 SRCYSIZE=4 DESXSIZE=0 DESYSIZE=4 -> Case 1 (No transfer)
//   Ky vong: hanh vi dung nhu cot Case cua Table 5-3.
//==============================================================================
`ifndef DMA350_VSEQ_2D_CORNER_06_SV
`define DMA350_VSEQ_2D_CORNER_06_SV

class dma350_vseq_2d_corner_06 extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_corner_06)

  function new(string name = "dma350_vseq_2d_corner_06");
    super.new(name);
    src_xsize = 0;
    src_ysize = 4;
    des_xsize = 0;
    des_ysize = 4;
    expect_idle = 1;
  endfunction

endclass : dma350_vseq_2d_corner_06

`endif // DMA350_VSEQ_2D_CORNER_06_SV
