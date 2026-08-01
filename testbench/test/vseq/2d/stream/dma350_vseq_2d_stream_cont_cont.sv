//==============================================================================
// dma350_vseq_2d_stream_cont_cont.sv
//   GROUP G - TRM Table 5-6 hang '2D Continue/Continue -> Yes'
//   To hop DUOC PHEP ro rang trong bang: XTYPE = Continue, YTYPE = Continue.
//   Ky vong: khong co config error; lenh chay het.
//==============================================================================
`ifndef DMA350_VSEQ_2D_STREAM_CONT_CONT_SV
`define DMA350_VSEQ_2D_STREAM_CONT_CONT_SV

class dma350_vseq_2d_stream_cont_cont extends dma350_vseq_2d_stream_base;
  `uvm_object_utils(dma350_vseq_2d_stream_cont_cont)

  function new(string name = "dma350_vseq_2d_stream_cont_cont");
    super.new(name);
    streamtype = ST_IN_OUT;
    xtype = XT_CONT;
    ytype = YT_CONT;
    drive_in = 1;
    in_beats = 32;
  endfunction

endclass : dma350_vseq_2d_stream_cont_cont

`endif // DMA350_VSEQ_2D_STREAM_CONT_CONT_SV
