//==============================================================================
// dma350_vseq_2d_basic_xaddrinc.sv
//   GROUP A - TRM 5.3.1 (Figure 5-6 '2D transfer with increments')
//   Doc nguon co gap trong dong: SRCXADDRINC = 2 -> chi lay 1 element trong 2.
//   Dich lien tuc (DESXADDRINC = 1).
//   Ky vong: chi doc dung cac element thu chan; ghi lien tuc tai dich.
//==============================================================================
`ifndef DMA350_VSEQ_2D_BASIC_XADDRINC_SV
`define DMA350_VSEQ_2D_BASIC_XADDRINC_SV

class dma350_vseq_2d_basic_xaddrinc extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_basic_xaddrinc)

  function new(string name = "dma350_vseq_2d_basic_xaddrinc");
    super.new(name);
    src_xaddrinc = 2;
    src_ystride  = 'h80;
    chk_src_drained = 1;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_basic_xaddrinc

`endif // DMA350_VSEQ_2D_BASIC_XADDRINC_SV
