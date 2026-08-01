//==============================================================================
// dma350_vseq_2d_life_pause_twice.sv
//   GROUP I - TRM 5.6, pause/resume NHIEU LAN trong mot khung 2D
//   Chen hai chu ky pause-resume o hai thoi diem khac nhau.
//   Ky vong: moi lan resume deu tiep dung cho; ket qua cuoi giong chay lien mach.
//==============================================================================
`ifndef DMA350_VSEQ_2D_LIFE_PAUSE_TWICE_SV
`define DMA350_VSEQ_2D_LIFE_PAUSE_TWICE_SV

class dma350_vseq_2d_life_pause_twice extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_life_pause_twice)

  function new(string name = "dma350_vseq_2d_life_pause_twice");
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
    cfg_2d();
    enable_ch(ch);

    for (int i = 0; i < 2; i++) begin
      apb_write(ch_addr(ch,O_CMD), 32'h1 << B_PAUSE);
      wait_ch_bit(ch, S_PAUSED, $sformatf("PAUSED lan %0d", i+1));
      apb_write(ch_addr(ch,O_CMD), 32'h1 << B_RESUME);
      repeat (5) begin
        bit [31:0] d;
        apb_read(ch_addr(ch,O_STATUS), d);
      end
    end

    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_life_pause_twice

`endif // DMA350_VSEQ_2D_LIFE_PAUSE_TWICE_SV
