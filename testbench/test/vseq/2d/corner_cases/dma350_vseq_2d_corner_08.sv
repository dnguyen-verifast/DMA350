//==============================================================================
// dma350_vseq_2d_corner_08.sv
//   GROUP C - TRM 5.3.2.1 Table 5-3 '2D corner cases', ID 8
//   SRCXSIZE=0 SRCYSIZE=4 DESXSIZE=8 DESYSIZE=4 -> Case 2 (Write only)
//   Ky vong: hanh vi dung nhu cot Case cua Table 5-3.
//==============================================================================
`ifndef DMA350_VSEQ_2D_CORNER_08_SV
`define DMA350_VSEQ_2D_CORNER_08_SV

class dma350_vseq_2d_corner_08 extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_corner_08)

  function new(string name = "dma350_vseq_2d_corner_08");
    super.new(name);
    src_xsize = 0;
    src_ysize = 4;
    des_xsize = 8;
    des_ysize = 4;
    xtype = XT_FILL;
    ytype = YT_FILL;
  endfunction

endclass : dma350_vseq_2d_corner_08

`endif // DMA350_VSEQ_2D_CORNER_08_SV
