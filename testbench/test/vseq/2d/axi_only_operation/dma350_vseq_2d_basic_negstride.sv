//==============================================================================
// dma350_vseq_2d_basic_negstride.sv
//   GROUP A - TRM 5.3.1 (Figure 5-6, DESYADDRSTRIDE am)
//   Stride dich AM: DESADDR bat dau o dong cuoi va lui dan moi dong.
//   Ky vong: dong nguon i duoc ghi vao dong (N-1-i) cua dich; stride so hoc dung.
//==============================================================================
`ifndef DMA350_VSEQ_2D_BASIC_NEGSTRIDE_SV
`define DMA350_VSEQ_2D_BASIC_NEGSTRIDE_SV

class dma350_vseq_2d_basic_negstride extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_basic_negstride)

  function new(string name = "dma350_vseq_2d_basic_negstride");
    super.new(name);
    des_addr    = 32'h0006_80C0;
    des_ystride = -'h40;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_basic_negstride

`endif // DMA350_VSEQ_2D_BASIC_NEGSTRIDE_SV
