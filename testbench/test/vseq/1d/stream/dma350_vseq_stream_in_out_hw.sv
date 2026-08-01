//==============================================================================
// dma350_vseq_stream_in_out_hw.sv
//   Bien the "Stream-in + out" voi TRANSIZE = halfword va so beat khac (4) de
//   phu them mot cau hinh kich thuoc khac cho duong stream.
//     USESTREAM=1, STREAMTYPE=00, src_n=des_n=4, TRANSIZE=halfword, lai 4 beat.
//==============================================================================
`ifndef DMA350_VSEQ_STREAM_IN_OUT_HW_SV
`define DMA350_VSEQ_STREAM_IN_OUT_HW_SV

class dma350_vseq_stream_in_out_hw extends dma350_vseq_stream_base;
  `uvm_object_utils(dma350_vseq_stream_in_out_hw)

  function new(string name = "dma350_vseq_stream_in_out_hw");
    super.new(name);
    use_stream = 1;
    streamtype = ST_IN_OUT;
    src_n      = 4;
    des_n      = 4;
    transize   = 3'd1;         // halfword
    drive_in   = 1;
    in_beats   = 4;
  endfunction

endclass : dma350_vseq_stream_in_out_hw

`endif // DMA350_VSEQ_STREAM_IN_OUT_HW_SV
