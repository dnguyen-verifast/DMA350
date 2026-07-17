//==============================================================================
// dma350_vseq_1d_single_desinc0_cont.sv
//   TRM 5.2.2 (List of cases for 1D WRAP) -- DESXADDRINC = 0 (FIFO dich, vi du TRM: SRC=3 DES=8)
//   XTYPE = continue
//
//   Ky vong: DESXADDRINC=0 (FIFO): source het -> dung. SRCXSIZE read va SRCXSIZE write.
//==============================================================================
`ifndef DMA350_VSEQ_1D_SINGLE_DESINC0_CONT_SV
`define DMA350_VSEQ_1D_SINGLE_DESINC0_CONT_SV

class dma350_vseq_1d_single_desinc0_cont extends dma350_vseq_1d_single_base;
  `uvm_object_utils(dma350_vseq_1d_single_desinc0_cont)

  function new(string name = "dma350_vseq_1d_single_desinc0_cont");
    super.new(name);
    src_xsize       = 3;
    des_xsize       = 8;
    src_xaddrinc    = 1;
    des_xaddrinc    = 0;
    xtype           = XT_CONT;
    expect_idle     = 0;
    chk_src_drained = 1;
    chk_des_drained = 0;
  endfunction

  virtual task body();
    super.body();   // POR + responder AXI5/AXIS
    run_1d(0);
  endtask

endclass : dma350_vseq_1d_single_desinc0_cont

`endif // DMA350_VSEQ_1D_SINGLE_DESINC0_CONT_SV
