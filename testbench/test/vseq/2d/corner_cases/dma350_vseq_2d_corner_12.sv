//==============================================================================
// dma350_vseq_2d_corner_12.sv
//   GROUP C - TRM 5.3.2.1 Table 5-3 '2D corner cases', ID 12
//   SRCXSIZE=8 SRCYSIZE=0 DESXSIZE=8 DESYSIZE=4 -> Case 2 (Write only)
//   Ky vong: hanh vi dung nhu cot Case cua Table 5-3.
//==============================================================================
`ifndef DMA350_VSEQ_2D_CORNER_12_SV
`define DMA350_VSEQ_2D_CORNER_12_SV

class dma350_vseq_2d_corner_12 extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_corner_12)

  function new(string name = "dma350_vseq_2d_corner_12");
    super.new(name);
    src_xsize = 8;
    src_ysize = 0;
    des_xsize = 8;
    des_ysize = 4;
    xtype = XT_FILL;
    ytype = YT_FILL;
  endfunction

endclass : dma350_vseq_2d_corner_12

`endif // DMA350_VSEQ_2D_CORNER_12_SV
