//==============================================================================
// dma350_vseq_2d_stream_cont_fill.sv
//   GROUP G - TRM Table 5-6 hang '2D Continue/Fill -> Yes'
//   Sau khi nhan TLAST, phan con lai cua vung dich duoc do FILLVAL.
//   Ky vong: khong config error; vung du duoc lap day bang FILLVAL.
//==============================================================================
`ifndef DMA350_VSEQ_2D_STREAM_CONT_FILL_SV
`define DMA350_VSEQ_2D_STREAM_CONT_FILL_SV

class dma350_vseq_2d_stream_cont_fill extends dma350_vseq_2d_stream_base;
  `uvm_object_utils(dma350_vseq_2d_stream_cont_fill)

  function new(string name = "dma350_vseq_2d_stream_cont_fill");
    super.new(name);
    streamtype = ST_IN_OUT;
    xtype = XT_CONT;
    ytype = YT_FILL;
    src_ysize = 2;
    des_ysize = 4;
    drive_in = 1;
    in_beats = 16;
    fillval = 32'h1234_5678;
  endfunction

endclass : dma350_vseq_2d_stream_cont_fill

`endif // DMA350_VSEQ_2D_STREAM_CONT_FILL_SV
