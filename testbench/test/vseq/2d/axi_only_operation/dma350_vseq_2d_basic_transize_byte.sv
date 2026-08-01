//==============================================================================
// dma350_vseq_2d_basic_transize_byte.sv
//   GROUP A - TRM 5.3.1 + 6.5.1.4 TRANSIZE
//   2D voi TRANSIZE = byte (000): dong 8 element = 8 byte, stride 0x10.
//   Ky vong: axsize = 0 tren bus; hinh hoc khoi dung theo don vi byte.
//==============================================================================
`ifndef DMA350_VSEQ_2D_BASIC_TRANSIZE_BYTE_SV
`define DMA350_VSEQ_2D_BASIC_TRANSIZE_BYTE_SV

class dma350_vseq_2d_basic_transize_byte extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_basic_transize_byte)

  function new(string name = "dma350_vseq_2d_basic_transize_byte");
    super.new(name);
    transize    = 3'd0;
    src_ystride = 'h10;
    des_ystride = 'h10;
    chk_src_drained = 1;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_basic_transize_byte

`endif // DMA350_VSEQ_2D_BASIC_TRANSIZE_BYTE_SV
