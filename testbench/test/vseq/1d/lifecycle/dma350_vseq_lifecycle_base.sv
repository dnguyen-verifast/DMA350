//==============================================================================
// dma350_vseq_lifecycle_base.sv
//------------------------------------------------------------------------------
// Base cho bo test DMA CHANNEL LIFECYCLE / EXECUTION STATES (TRM 5.6) - CH0.
// Cac trang thai (theo bang anh):
//   Disabled        : channel off (sau reset / sau khi lenh xong / DISABLECMD)
//   Enabled(running): dang thuc thi mot lenh
//   Paused          : tam dung, co the resume (PAUSECMD -> RESUMECMD)
//   Stopped         : dung han (STOPCMD)
//   Halted (CTI)    : dung de debug qua Cross Trigger Interface (halt/restart)
//   Error handling  : hanh vi khi loi cau hinh / transfer
//
// Chi TAO test + vseq (khong sua scoreboard). Cac vseq con set knob / override
// body() roi goi cac helper o day. Dung lenh copy DAI (xsize lon) de kip chen
// pause/stop/halt giua chung truoc khi lenh xong.
//==============================================================================
`ifndef DMA350_VSEQ_LIFECYCLE_BASE_SV
`define DMA350_VSEQ_LIFECYCLE_BASE_SV

class dma350_vseq_lifecycle_base extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_lifecycle_base)

  int unsigned ch       = 0;
  bit [31:0]   src_addr = 32'h0000_8000;
  bit [31:0]   des_addr = 32'h0000_9000;
  int unsigned xsize    = 128;             // copy dai de con dang chay khi chen dieu khien
  bit [2:0]    transize = 3'd2;            // word

  // CH_AUTOCFG.CMDRESTARTINFEN (bit16) : tu dong restart vo han
  localparam bit [31:0] CMDRESTARTINFEN = 32'h0001_0000;

  function new(string name = "dma350_vseq_lifecycle_base");
    super.new(name);
  endfunction

  // Cau hinh 1 copy 1D (dung cac knob). transize co the doi de tao config error.
  virtual task cfg_copy();
    cfg_ch(.ch(ch), .src(src_addr), .des(des_addr), .xsize(xsize), .transize(transize));
  endtask

  // Doc CH_CMD[0] (ENABLECMD) : 1 = dang chay, 0 = disabled/off.
  virtual task check_enabled(bit exp_enabled, string what);
    bit [31:0] cmd;
    apb_read(ch_addr(ch,O_CMD), cmd);
    if (cmd[B_ENABLE] !== exp_enabled)
      `uvm_error(get_type_name(), $sformatf(
        "CH%0d %s: ENABLECMD=%0b (mong doi %0b) CH_CMD=0x%08h",
        ch, what, cmd[B_ENABLE], exp_enabled, cmd))
    else
      `uvm_info(get_type_name(), $sformatf(
        "CH%0d %s: ENABLECMD=%0b (dung) CH_CMD=0x%08h", ch, what, cmd[B_ENABLE], cmd), UVM_LOW)
  endtask
  // B_ENABLE (=0) ke thua tu dma350_vseq_base

  virtual task body();
    super.body();                // POR + responders
  endtask

endclass : dma350_vseq_lifecycle_base

`endif // DMA350_VSEQ_LIFECYCLE_BASE_SV
