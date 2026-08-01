//==============================================================================
// dma350_vseq_2d_basic_desinc0.sv
//   GROUP A - TRM 5.3.1 (Figure 5-6: DESXADDRINC = 0 -> ghi vao FIFO)
//   Dich la mot FIFO: DESXADDRINC = 0, moi element trong dong ghi cung dia chi;
//   sang dong moi thi DESADDR nhay theo stride nho (0x4).
//   Ky vong: moi ghi trong mot dong deu vao cung DESADDR (burst FIXED).
//==============================================================================
`ifndef DMA350_VSEQ_2D_BASIC_DESINC0_SV
`define DMA350_VSEQ_2D_BASIC_DESINC0_SV

class dma350_vseq_2d_basic_desinc0 extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_basic_desinc0)

  function new(string name = "dma350_vseq_2d_basic_desinc0");
    super.new(name);
    des_xaddrinc = 0;
    des_ystride  = 'h4;
    chk_src_drained = 1;
  endfunction

endclass : dma350_vseq_2d_basic_desinc0

`endif // DMA350_VSEQ_2D_BASIC_DESINC0_SV
