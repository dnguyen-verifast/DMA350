//==============================================================================
// dma350_vseq_1d_single_src0_des0_cont.sv
//   TRM 5.2.2 (List of cases for 1D WRAP) -- SRCXSIZE == 0, DESXSIZE == 0
//   XTYPE = continue
//
//   Ky vong: Transfer KHONG khoi dong (co the chi dang cho trigger). TRM danh dau: Manual.
//==============================================================================
`ifndef DMA350_VSEQ_1D_SINGLE_SRC0_DES0_CONT_SV
`define DMA350_VSEQ_1D_SINGLE_SRC0_DES0_CONT_SV

class dma350_vseq_1d_single_src0_des0_cont extends dma350_vseq_1d_single_base;
  `uvm_object_utils(dma350_vseq_1d_single_src0_des0_cont)

  function new(string name = "dma350_vseq_1d_single_src0_des0_cont");
    super.new(name);
    src_xsize       = 0;
    des_xsize       = 0;
    src_xaddrinc    = 1;
    des_xaddrinc    = 1;
    xtype           = XT_CONT;
    expect_idle     = 1;
    chk_src_drained = 0;
    chk_des_drained = 0;
  endfunction

  virtual task body();
    super.body();   // POR + responder AXI5/AXIS
    run_1d(0);
  endtask

endclass : dma350_vseq_1d_single_src0_des0_cont

`endif // DMA350_VSEQ_1D_SINGLE_SRC0_DES0_CONT_SV
