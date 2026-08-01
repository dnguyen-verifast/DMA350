//==============================================================================
// dma350_vseq_2d_wrap_x_eq.sv
//   GROUP B - TRM 5.3.2.2 'SRCXSIZE == DESXSIZE' + 'SRCYSIZE == DESYSIZE'
//   Kich thuoc bang nhau -> wrap khong co tac dung, la copy 2D thuong.
//   Ky vong: ket qua giong het 2d_basic_continue du XTYPE/YTYPE = wrap.
//==============================================================================
`ifndef DMA350_VSEQ_2D_WRAP_X_EQ_SV
`define DMA350_VSEQ_2D_WRAP_X_EQ_SV

class dma350_vseq_2d_wrap_x_eq extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_wrap_x_eq)

  function new(string name = "dma350_vseq_2d_wrap_x_eq");
    super.new(name);
    xtype = XT_WRAP;
    ytype = YT_WRAP;
    chk_src_drained = 1;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_wrap_x_eq

`endif // DMA350_VSEQ_2D_WRAP_X_EQ_SV
