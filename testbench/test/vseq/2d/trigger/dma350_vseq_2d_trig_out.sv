//==============================================================================
// dma350_vseq_2d_trig_out.sv
//   GROUP F - TRM 5.4.2 'Trigger outputs' tren lenh 2D
//   Lenh 2D tu chay, khi xong thi phat trigger-out ra cong ngoai va DUNG lai cho ack.
//   Ky vong: trigout req chi len SAU dong cuoi (khong phai moi dong);
//            lenh chua DONE cho toi khi nhan ack.
//==============================================================================
`ifndef DMA350_VSEQ_2D_TRIG_OUT_SV
`define DMA350_VSEQ_2D_TRIG_OUT_SV

class dma350_vseq_2d_trig_out extends dma350_vseq_2d_trig_base;
  `uvm_object_utils(dma350_vseq_2d_trig_out)

  function new(string name = "dma350_vseq_2d_trig_out");
    super.new(name);
    use_srctrig = 0;
    use_trigout = 1;
    trigout_type = TT_HW;
    trigout_sel = 8'd0;
  endfunction

  virtual task body();
    super.body();
    cfg_trig_ch();
    enable_ch(ch);
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_trig_out

`endif // DMA350_VSEQ_2D_TRIG_OUT_SV
