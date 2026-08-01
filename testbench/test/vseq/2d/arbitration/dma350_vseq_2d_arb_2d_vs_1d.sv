//==============================================================================
// dma350_vseq_2d_arb_2d_vs_1d.sv
//   GROUP L - TRM 5.8.1 'Arbitration requests', tron 2D va 1D
//   CH0 chay khung 2D dai, CH1 chay copy 1D ngan cung luc.
//   Ky vong: hai kieu lenh chia se bus cong bang; khong channel nao bi doi mai.
//==============================================================================
`ifndef DMA350_VSEQ_2D_ARB_2D_VS_1D_SV
`define DMA350_VSEQ_2D_ARB_2D_VS_1D_SV

class dma350_vseq_2d_arb_2d_vs_1d extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_arb_2d_vs_1d)

  function new(string name = "dma350_vseq_2d_arb_2d_vs_1d");
    super.new(name);
    src_xsize = 32;
    des_xsize = 32;
    src_ysize = 16;
    des_ysize = 16;
    src_ystride = 'h100;
    des_ystride = 'h100;
  endfunction

  virtual task body();
    super.body();

    cfg_2d(0);                                                    // CH0 : 2D dai
    cfg_ch(.ch(1), .src(32'h000C_0000), .des(32'h000C_4000), .xsize(16));  // CH1 : 1D ngan

    enable_ch(0);
    enable_ch(1);
    wait_ch_done(1);
    wait_ch_done(0);
    clear_ch_status(0);
    clear_ch_status(1);
  endtask

endclass : dma350_vseq_2d_arb_2d_vs_1d

`endif // DMA350_VSEQ_2D_ARB_2D_VS_1D_SV
