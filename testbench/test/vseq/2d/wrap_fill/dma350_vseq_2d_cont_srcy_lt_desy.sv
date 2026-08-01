//==============================================================================
// dma350_vseq_2d_cont_srcy_lt_desy.sv
//   GROUP B - TRM 5.3.2.2 'SRCYSIZE < DESYSIZE', YTYPE = continue
//   Continue: het dong nguon la dung, KHONG wrap va KHONG fill.
//   Ky vong: chi 2 dong dau cua vung dich bi ghi; 3 dong con lai giu nguyen.
//==============================================================================
`ifndef DMA350_VSEQ_2D_CONT_SRCY_LT_DESY_SV
`define DMA350_VSEQ_2D_CONT_SRCY_LT_DESY_SV

class dma350_vseq_2d_cont_srcy_lt_desy extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_cont_srcy_lt_desy)

  function new(string name = "dma350_vseq_2d_cont_srcy_lt_desy");
    super.new(name);
    src_ysize = 2;
    des_ysize = 5;
    ytype = YT_CONT;
  endfunction

endclass : dma350_vseq_2d_cont_srcy_lt_desy

`endif // DMA350_VSEQ_2D_CONT_SRCY_LT_DESY_SV
