//==============================================================================
// dma350_vseq_power_qchannel.sv
//   "Q-Channel clock - Clock gating via LPI Q-Channel"
//   - IDLE : quiesce/wake phai duoc CHAP NHAN (co the tat clock).
//   - BUSY : bat 1 copy dai roi xin quiesce -> mong doi DENY (dang hoat dong).
//   (scoreboard process_lpi soi: accept khi busy = loi)
//==============================================================================
`ifndef DMA350_VSEQ_POWER_QCHANNEL_SV
`define DMA350_VSEQ_POWER_QCHANNEL_SV

class dma350_vseq_power_qchannel extends dma350_vseq_power_base;
  `uvm_object_utils(dma350_vseq_power_qchannel)

  function new(string name = "dma350_vseq_power_qchannel");
    super.new(name);
    xsize = 64;                  // copy dai de con busy khi xin quiesce
  endfunction

  virtual task body();
    super.body();

    // IDLE: clock quiesce/wake duoc chap nhan
    qch_cycle("idle");

    // BUSY: dang chay -> xin quiesce (DUT nen deny)
    cfg_ch(.ch(ch), .src(src_addr), .des(des_addr), .xsize(xsize));
    enable_ch(ch);
    qch_cycle("busy");
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_power_qchannel

`endif // DMA350_VSEQ_POWER_QCHANNEL_SV
