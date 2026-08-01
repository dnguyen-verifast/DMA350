//==============================================================================
// dma350_vseq_2d_fill_y.sv
//   GROUP B - TRM 5.3.2.2 'SRCYSIZE < DESYSIZE', YTYPE = fill
//   Het du lieu nguon (2 dong) thi cac dong dich con lai duoc do FILLVAL.
//   Ky vong: 2 dong dau la du lieu that, 2 dong sau toan FILLVAL.
//==============================================================================
`ifndef DMA350_VSEQ_2D_FILL_Y_SV
`define DMA350_VSEQ_2D_FILL_Y_SV

class dma350_vseq_2d_fill_y extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_fill_y)

  function new(string name = "dma350_vseq_2d_fill_y");
    super.new(name);
    src_ysize = 2;
    des_ysize = 4;
    ytype     = YT_FILL;
    fillval   = 32'hDEAD_BEEF;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_fill_y

`endif // DMA350_VSEQ_2D_FILL_Y_SV
