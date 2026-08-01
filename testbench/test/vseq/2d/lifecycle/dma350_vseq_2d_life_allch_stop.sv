//==============================================================================
// dma350_vseq_2d_life_allch_stop.sv
//   GROUP I - TRM 4.8.2 'Stop and pause control' (all-channel) tren 2D
//   Dung TAT CA channel non-secure qua NSEC_CTRL.ALLCHSTOP trong khi CH0 chay 2D.
//   Ky vong: CH0 dung sach; NSEC_STATUS.STAT_ALLCHSTOPPED set.
//==============================================================================
`ifndef DMA350_VSEQ_2D_LIFE_ALLCH_STOP_SV
`define DMA350_VSEQ_2D_LIFE_ALLCH_STOP_SV

class dma350_vseq_2d_life_allch_stop extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_life_allch_stop)

  function new(string name = "dma350_vseq_2d_life_allch_stop");
    super.new(name);
    src_xsize = 32;
    des_xsize = 32;
    src_ysize = 16;
    des_ysize = 16;
    src_ystride = 'h100;
    des_ystride = 'h100;
  endfunction

  // DMANSECCTRL frame o 0x0200 (TRM 6.3)
  localparam bit [31:0] NSEC_STATUS_ADDR = 32'h0208;
  localparam bit [31:0] NSEC_CTRL_ADDR   = 32'h020C;
  localparam int        NS_ALLCHSTOP     = 8;      // NSEC_CTRL[8]
  localparam int        NS_STAT_ALLSTOP  = 18;     // NSEC_STATUS[18]

  virtual task body();
    bit [31:0] ns;
    super.body();
    cfg_2d();
    enable_ch(ch);

    apb_write(NSEC_CTRL_ADDR, 32'h1 << NS_ALLCHSTOP);

    repeat (poll_limit) begin
      apb_read(NSEC_STATUS_ADDR, ns);
      if (ns[NS_STAT_ALLSTOP]) break;
    end
    if (!ns[NS_STAT_ALLSTOP])
      `uvm_error(get_type_name(), $sformatf(
        "TIMEOUT cho NSEC_STATUS.STAT_ALLCHSTOPPED (doc 0x%08h)", ns))
    else
      `uvm_info(get_type_name(), $sformatf(
        "ALLCHSTOP da dung het channel non-secure (NSEC_STATUS=0x%08h)", ns), UVM_LOW)

    apb_write(NSEC_STATUS_ADDR, 32'h1 << NS_STAT_ALLSTOP);   // W1C
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_life_allch_stop

`endif // DMA350_VSEQ_2D_LIFE_ALLCH_STOP_SV
