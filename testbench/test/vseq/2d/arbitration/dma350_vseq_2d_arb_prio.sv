//==============================================================================
// dma350_vseq_2d_arb_prio.sv
//   GROUP L - TRM 5.8.2 'Arbitration scheme' (fixed priority) tren 2D
//   CH1 dat CHPRIO cao hon CH0 (CH_CTRL[7:4]) -> CH1 duoc uu tien tren bus.
//   Ky vong: arqos/awqos cua CH1 cao hon; CH1 nhin chung xong truoc CH0.
//==============================================================================
`ifndef DMA350_VSEQ_2D_ARB_PRIO_SV
`define DMA350_VSEQ_2D_ARB_PRIO_SV

class dma350_vseq_2d_arb_prio extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_arb_prio)

  function new(string name = "dma350_vseq_2d_arb_prio");
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

    cfg_2d(0);                             // CHPRIO = 0 (thap)
    src_addr = 32'h000B_0000;  des_addr = 32'h000B_8000;
    extra_ctrl = (32'hF << 4);             // CHPRIO = 15 (cao nhat)
    cfg_2d(1);
    extra_ctrl = 32'h0;

    enable_ch(0);
    enable_ch(1);
    wait_ch_done(1);
    wait_ch_done(0);
    clear_ch_status(0);
    clear_ch_status(1);
  endtask

endclass : dma350_vseq_2d_arb_prio

`endif // DMA350_VSEQ_2D_ARB_PRIO_SV
