//==============================================================================
// dma350_vseq_2d_xform_rotate_180.sv
//   GROUP D - TRM 5.3.1 Figure 5-7 'Rotation' 180 do
//   Ca DESXADDRINC va DESYADDRSTRIDE deu am (mirror X + mirror Y).
//   Ky vong: anh dich = anh nguon xoay 180 do.
//==============================================================================
`ifndef DMA350_VSEQ_2D_XFORM_ROTATE_180_SV
`define DMA350_VSEQ_2D_XFORM_ROTATE_180_SV

class dma350_vseq_2d_xform_rotate_180 extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_xform_rotate_180)

  function new(string name = "dma350_vseq_2d_xform_rotate_180");
    super.new(name);
    des_addr     = 32'h0006_80DC;
    des_xaddrinc = -1;
    des_ystride  = -'h40;
    chk_src_drained = 1;
  endfunction

endclass : dma350_vseq_2d_xform_rotate_180

`endif // DMA350_VSEQ_2D_XFORM_ROTATE_180_SV
