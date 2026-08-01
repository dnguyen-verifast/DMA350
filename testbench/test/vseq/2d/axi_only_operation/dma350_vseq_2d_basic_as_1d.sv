//==============================================================================
// dma350_vseq_2d_basic_as_1d.sv
//   GROUP A - TRM 5.3.1 ('1D transfers can still be created ... setting YSIZE to 1')
//   May 2D chay lenh 1D: SRCYSIZE = DESYSIZE = 1, XSIZE = 32.
//   Ky vong: ket qua byte-identical voi test 1D continue tuong ung.
//==============================================================================
`ifndef DMA350_VSEQ_2D_BASIC_AS_1D_SV
`define DMA350_VSEQ_2D_BASIC_AS_1D_SV

class dma350_vseq_2d_basic_as_1d extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_basic_as_1d)

  function new(string name = "dma350_vseq_2d_basic_as_1d");
    super.new(name);
    src_xsize = 32;
    des_xsize = 32;
    src_ysize = 1;
    des_ysize = 1;
    chk_src_drained = 1;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_basic_as_1d

`endif // DMA350_VSEQ_2D_BASIC_AS_1D_SV
