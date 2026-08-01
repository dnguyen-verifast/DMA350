//==============================================================================
// dma350_vseq_2d_fill_x.sv
//   GROUP B - TRM 5.3.2.2 'SRCXSIZE < DESXSIZE', XTYPE = fill
//   Moi dong dich rong hon dong nguon -> phan du ben phai do FILLVAL.
//   Ky vong: 4 element dau moi dong la du lieu, 4 element sau la FILLVAL.
//==============================================================================
`ifndef DMA350_VSEQ_2D_FILL_X_SV
`define DMA350_VSEQ_2D_FILL_X_SV

class dma350_vseq_2d_fill_x extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_fill_x)

  function new(string name = "dma350_vseq_2d_fill_x");
    super.new(name);
    src_xsize   = 4;
    des_xsize   = 8;
    xtype       = XT_FILL;
    src_ystride = 'h20;
    fillval = 32'h5A5A_A5A5;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_fill_x

`endif // DMA350_VSEQ_2D_FILL_X_SV
