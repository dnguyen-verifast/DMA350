//==============================================================================
// dma350_vseq_2d_xform_mirror_x.sv
//   GROUP D - TRM 5.3.1 Figure 5-7 'Mirroring' (lat ngang)
//   DESXADDRINC = -1 va DESADDR tro toi element CUOI cua dong dich.
//   Ky vong: moi dong bi dao thu tu trai<->phai; thu tu dong giu nguyen.
//==============================================================================
`ifndef DMA350_VSEQ_2D_XFORM_MIRROR_X_SV
`define DMA350_VSEQ_2D_XFORM_MIRROR_X_SV

class dma350_vseq_2d_xform_mirror_x extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_xform_mirror_x)

  function new(string name = "dma350_vseq_2d_xform_mirror_x");
    super.new(name);
    des_addr     = 32'h0006_801C;
    des_xaddrinc = -1;
    des_ystride = 'h40;
    chk_src_drained = 1;
  endfunction

endclass : dma350_vseq_2d_xform_mirror_x

`endif // DMA350_VSEQ_2D_XFORM_MIRROR_X_SV
