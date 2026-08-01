//==============================================================================
// dma350_vseq_2d_xform_mirror_y.sv
//   GROUP D - TRM 5.3.1 Figure 5-7 'Mirroring' (lat doc)
//   DESYADDRSTRIDE am va DESADDR tro toi DONG CUOI cua vung dich.
//   Ky vong: thu tu dong bi lat tren<->duoi; moi dong giu nguyen thu tu element.
//==============================================================================
`ifndef DMA350_VSEQ_2D_XFORM_MIRROR_Y_SV
`define DMA350_VSEQ_2D_XFORM_MIRROR_Y_SV

class dma350_vseq_2d_xform_mirror_y extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_xform_mirror_y)

  function new(string name = "dma350_vseq_2d_xform_mirror_y");
    super.new(name);
    des_addr    = 32'h0006_80C0;
    des_ystride = -'h40;
    chk_src_drained = 1;
  endfunction

endclass : dma350_vseq_2d_xform_mirror_y

`endif // DMA350_VSEQ_2D_XFORM_MIRROR_Y_SV
