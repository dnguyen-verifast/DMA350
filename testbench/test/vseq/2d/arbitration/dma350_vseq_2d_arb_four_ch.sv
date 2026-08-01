//==============================================================================
// dma350_vseq_2d_arb_four_ch.sv
//   GROUP L - TRM 5.8.2, bon channel cung chay 2D
//   CH0..CH3 moi channel mot khung 2D tren vung nho rieng.
//   Ky vong: round-robin least-recently-granted; tat ca deu ve DONE, khong doi vinh vien.
//==============================================================================
`ifndef DMA350_VSEQ_2D_ARB_FOUR_CH_SV
`define DMA350_VSEQ_2D_ARB_FOUR_CH_SV

class dma350_vseq_2d_arb_four_ch extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_arb_four_ch)

  function new(string name = "dma350_vseq_2d_arb_four_ch");
    super.new(name);
    src_ysize = 8;
    des_ysize = 8;
  endfunction

  virtual task body();
    super.body();

    for (int i = 0; i < 4; i++) begin
      src_addr = 32'h0010_0000 + (i << 16);
      des_addr = 32'h0018_0000 + (i << 16);
      cfg_2d(i);
    end
    for (int i = 0; i < 4; i++) enable_ch(i);
    for (int i = 0; i < 4; i++) begin
      wait_ch_done(i);
      clear_ch_status(i);
    end
  endtask

endclass : dma350_vseq_2d_arb_four_ch

`endif // DMA350_VSEQ_2D_ARB_FOUR_CH_SV
