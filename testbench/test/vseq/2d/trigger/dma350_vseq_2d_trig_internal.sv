//==============================================================================
// dma350_vseq_2d_trig_internal.sv
//   GROUP F - TRM 5.4.4 'Internal trigger connection' tren lenh 2D
//   CH1 lam lenh 2D nhung cho trigger noi bo tu CH0; CH0 chay xong thi phat
//   trigger-out noi thang vao trigger-in cua CH1.
//   Ky vong: CH1 chi bat dau sau khi CH0 DONE (day chuyen 2D).
//==============================================================================
`ifndef DMA350_VSEQ_2D_TRIG_INTERNAL_SV
`define DMA350_VSEQ_2D_TRIG_INTERNAL_SV

class dma350_vseq_2d_trig_internal extends dma350_vseq_2d_trig_base;
  `uvm_object_utils(dma350_vseq_2d_trig_internal)

  function new(string name = "dma350_vseq_2d_trig_internal");
    super.new(name);
    ch = 1;
    use_srctrig = 1;
    trig_type = TT_INTERNAL;
    trig_sel = 8'd0;
  endfunction

  virtual task body();
    super.body();

    // CH1: lenh 2D cho trigger noi bo tu CH0
    cfg_trig_ch();
    enable_ch(ch);
    check_waiting_trigger("CH1 cho internal trigger tu CH0 (2D)");

    // CH0: copy 1D ngan, bat trigger-out kieu INTERNAL
    apb_write(ch_addr(0,O_TRIGOUTCFG), {16'h0, 4'h0, 2'b00, TT_INTERNAL, 8'd1});
    cfg_ch(.ch(0), .src(32'h0009_0000), .des(32'h0009_4000), .xsize(8));
    apb_write(ch_addr(0,O_CTRL),
              (32'h1 << 21) | (32'h1 << 27) | (32'h1 << 9) | {29'b0, transize});
    enable_ch(0);
    wait_ch_done(0);
    clear_ch_status(0);

    // CH1 phai chay tiep sau khi nhan internal trigger
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_trig_internal

`endif // DMA350_VSEQ_2D_TRIG_INTERNAL_SV
