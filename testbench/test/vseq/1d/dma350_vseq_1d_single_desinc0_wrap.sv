//==============================================================================
// dma350_vseq_1d_single_desinc0_wrap.sv
//   TRM 5.2.2 (List of cases for 1D WRAP) -- DESXADDRINC = 0 (FIFO dich, vi du TRM: SRC=3 DES=8)
//   XTYPE = wrap
//
//   Ky vong: DESXADDRINC=0: dia chi dich khong tang nen khong wrap that; source duoc lap lai vao FIFO. Vi du SRC=3/DES=8 -> des_data[i] = src_data[i%3].
//==============================================================================
`ifndef DMA350_VSEQ_1D_SINGLE_DESINC0_WRAP_SV
`define DMA350_VSEQ_1D_SINGLE_DESINC0_WRAP_SV

class dma350_vseq_1d_single_desinc0_wrap extends dma350_vseq_1d_single_base;
  `uvm_object_utils(dma350_vseq_1d_single_desinc0_wrap)

  function new(string name = "dma350_vseq_1d_single_desinc0_wrap");
    super.new(name);
    src_xsize       = 3;
    des_xsize       = 8;
    src_xaddrinc    = 1;
    des_xaddrinc    = 0;
    xtype           = XT_WRAP;
    expect_idle     = 0;
    chk_src_drained = 0;
    chk_des_drained = 1;
  endfunction

  virtual task body();
    super.body();   // POR + responder AXI5/AXIS
    run_1d(0);
  endtask

endclass : dma350_vseq_1d_single_desinc0_wrap

`endif // DMA350_VSEQ_1D_SINGLE_DESINC0_WRAP_SV
