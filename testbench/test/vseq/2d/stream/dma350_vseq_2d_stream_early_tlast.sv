//==============================================================================
// dma350_vseq_2d_stream_early_tlast.sv
//   GROUP G - TRM 5.5.1 'When tlast is received while DESXSIZE ... greater than 0'
//   str_in ket thuc SOM (it beat hon vung dich 2D can).
//   Ky vong: lenh ket thuc ngay tai giua dong nhu TRM mo ta, khong treo.
//==============================================================================
`ifndef DMA350_VSEQ_2D_STREAM_EARLY_TLAST_SV
`define DMA350_VSEQ_2D_STREAM_EARLY_TLAST_SV

class dma350_vseq_2d_stream_early_tlast extends dma350_vseq_2d_stream_base;
  `uvm_object_utils(dma350_vseq_2d_stream_early_tlast)

  function new(string name = "dma350_vseq_2d_stream_early_tlast");
    super.new(name);
    streamtype = ST_IN_ONLY;
    src_n = 0;
    src_ysize = 0;
    drive_in = 1;
    in_beats = 10;
    xtype = XT_CONT;
    ytype = YT_CONT;
  endfunction

endclass : dma350_vseq_2d_stream_early_tlast

`endif // DMA350_VSEQ_2D_STREAM_EARLY_TLAST_SV
