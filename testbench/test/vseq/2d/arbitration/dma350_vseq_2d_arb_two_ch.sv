//==============================================================================
// dma350_vseq_2d_arb_two_ch.sv
//   GROUP L - TRM 5.8 'Arbitration', hai channel cung chay 2D
//   CH0 va CH1 cung phat khung 2D -> BIU phai chia bang round-robin (cung uu tien).
//   Ky vong: ca hai channel deu DONE; du lieu hai khung khong lan sang nhau.
//==============================================================================
`ifndef DMA350_VSEQ_2D_ARB_TWO_CH_SV
`define DMA350_VSEQ_2D_ARB_TWO_CH_SV

class dma350_vseq_2d_arb_two_ch extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_arb_two_ch)

  function new(string name = "dma350_vseq_2d_arb_two_ch");
    super.new(name);

  endfunction

  virtual task body();
    super.body();

    // CH0
    cfg_2d(0);
    // CH1: vung nho khac
    src_addr = 32'h000A_0000;  des_addr = 32'h000A_8000;
    cfg_2d(1);

    enable_ch(0);
    enable_ch(1);
    wait_ch_done(0);
    wait_ch_done(1);
    clear_ch_status(0);
    clear_ch_status(1);
  endtask

endclass : dma350_vseq_2d_arb_two_ch

`endif // DMA350_VSEQ_2D_ARB_TWO_CH_SV
