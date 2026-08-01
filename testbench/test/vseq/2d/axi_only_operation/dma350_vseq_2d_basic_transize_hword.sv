//==============================================================================
// dma350_vseq_2d_basic_transize_hword.sv
//   GROUP A - TRM 5.3.1 + 6.5.1.4 TRANSIZE
//   2D voi TRANSIZE = halfword (001): dong 8 element = 16 byte, stride 0x20.
//   Ky vong: axsize = 1 tren bus; dia chi can chinh theo 2 byte.
//==============================================================================
`ifndef DMA350_VSEQ_2D_BASIC_TRANSIZE_HWORD_SV
`define DMA350_VSEQ_2D_BASIC_TRANSIZE_HWORD_SV

class dma350_vseq_2d_basic_transize_hword extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_basic_transize_hword)

  function new(string name = "dma350_vseq_2d_basic_transize_hword");
    super.new(name);
    transize    = 3'd1;
    src_ystride = 'h20;
    des_ystride = 'h20;
    chk_src_drained = 1;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_basic_transize_hword

`endif // DMA350_VSEQ_2D_BASIC_TRANSIZE_HWORD_SV
