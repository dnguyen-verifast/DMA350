//==============================================================================
// dma350_vseq_lib.sv
//------------------------------------------------------------------------------
// 10 virtual sequence co ban cho DMA-350. Tat ca ke thua dma350_vseq_base
// (POR + responder AXI5/AXIS chay nen trong super.body()).
//
//   1  dma350_vseq_reg_access        : ghi/doc-lai thanh ghi config
//   2  dma350_vseq_single_copy       : copy 1D 64 byte, channel 0
//   3  dma350_vseq_fill              : FILL mode (khong doc nguon)
//   4  dma350_vseq_2d_copy           : copy 2D nhieu dong (ysize/stride)
//   5  dma350_vseq_wrap              : XTYPE=wrap
//   6  dma350_vseq_multi_channel     : 4 channel chay song song
//   7  dma350_vseq_stop_pause        : PAUSE/RESUME roi STOP giua chung
//   8  dma350_vseq_allch_stop_pause  : allch stop/pause qua Status/Control agent
//   9  dma350_vseq_lowpower          : Q/P-channel khi idle va khi busy
//  10  dma350_vseq_gpo               : GPO set/readback + doi chieu gpo_ch
//==============================================================================
`ifndef DMA350_VSEQ_LIB_SV
`define DMA350_VSEQ_LIB_SV

//------------------------------------------------------------------------------
// 1) Register access : ghi cac thanh ghi config roi doc lai so khop
//------------------------------------------------------------------------------
class dma350_vseq_reg_access extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_reg_access)
  function new(string name="dma350_vseq_reg_access"); super.new(name); endfunction

  virtual task body();
    super.body();
    // cac thanh ghi config RW co the ghi/doc tu do khi channel disabled
    apb_write(ch_addr(0,O_SRCADDR),  32'hA5A5_1000);
    apb_write(ch_addr(0,O_DESADDR),  32'h5A5A_2000);
    apb_write(ch_addr(0,O_XSIZE),    32'h0010_0010);
    apb_write(ch_addr(0,O_XADDRINC), 32'h0001_0001);
    apb_write(ch_addr(0,O_FILLVAL),  32'hDEAD_BEEF);
    apb_write(ch_addr(0,O_YSIZE),    32'h0000_0004);

    apb_check(ch_addr(0,O_SRCADDR),  32'hA5A5_1000);
    apb_check(ch_addr(0,O_DESADDR),  32'h5A5A_2000);
    apb_check(ch_addr(0,O_XSIZE),    32'h0010_0010);
    apb_check(ch_addr(0,O_XADDRINC), 32'h0001_0001);
    apb_check(ch_addr(0,O_FILLVAL),  32'hDEAD_BEEF);
    apb_check(ch_addr(0,O_YSIZE),    32'h0000_0004, 32'h0000_FFFF);
    `uvm_info(get_type_name(), "register access OK", UVM_LOW)
  endtask
endclass

//------------------------------------------------------------------------------
// 2) Single copy 1D : 16 word (64 byte) tu 0x1000 -> 0x2000, channel 0
//------------------------------------------------------------------------------
class dma350_vseq_single_copy extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_single_copy)
  function new(string name="dma350_vseq_single_copy"); super.new(name); endfunction

  virtual task body();
    super.body();
    cfg_ch_1d(.ch(0), .src(32'h0000_1000), .des(32'h0000_2000), .xsize(16));
    enable_ch(0);
    wait_ch_done(0);
    clear_ch_status(0);
  endtask
endclass

//------------------------------------------------------------------------------
// 3) FILL : ghi 32 word gia tri FILLVAL, khong doc nguon (XTYPE=011)
//------------------------------------------------------------------------------
class dma350_vseq_fill extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_fill)
  function new(string name="dma350_vseq_fill"); super.new(name); endfunction

  virtual task body();
    super.body();
    apb_write(ch_addr(0,O_DESADDR),  32'h0000_3000);
    apb_write(ch_addr(0,O_DESADDRHI),32'h0);
    apb_write(ch_addr(0,O_XSIZE),    {16'd32, 16'd32});
    apb_write(ch_addr(0,O_XADDRINC), 32'h0001_0001);
    apb_write(ch_addr(0,O_FILLVAL),  32'hCAFE_F00D);
    // TRANSIZE=word, XTYPE=fill(011), DONETYPE=end-of-command
    apb_write(ch_addr(0,O_CTRL), (32'h1<<21) | (32'h3<<9) | 32'h2);
    apb_write(ch_addr(0,O_INTREN), 32'h3);
    enable_ch(0);
    wait_ch_done(0);
    clear_ch_status(0);
  endtask
endclass

//------------------------------------------------------------------------------
// 4) Copy 2D : 4 dong x 8 word, stride nguon/dich 0x40 byte
//------------------------------------------------------------------------------
class dma350_vseq_2d_copy extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_2d_copy)
  function new(string name="dma350_vseq_2d_copy"); super.new(name); endfunction

  virtual task body();
    super.body();
    apb_write(ch_addr(0,O_SRCADDR),    32'h0000_4000);
    apb_write(ch_addr(0,O_SRCADDRHI),  32'h0);
    apb_write(ch_addr(0,O_DESADDR),    32'h0000_5000);
    apb_write(ch_addr(0,O_DESADDRHI),  32'h0);
    apb_write(ch_addr(0,O_XSIZE),      {16'd8, 16'd8});
    apb_write(ch_addr(0,O_XADDRINC),   32'h0001_0001);
    apb_write(ch_addr(0,O_YSIZE),      32'h0000_0004);           // 4 dong
    apb_write(ch_addr(0,O_YADDRSTRIDE),{16'h0040, 16'h0040});    // des|src stride
    // TRANSIZE=word, XTYPE=cont, YTYPE=cont(2D), DONETYPE=end-of-command
    apb_write(ch_addr(0,O_CTRL), (32'h1<<21) | (32'h1<<12) | (32'h1<<9) | 32'h2);
    apb_write(ch_addr(0,O_INTREN), 32'h3);
    enable_ch(0);
    wait_ch_done(0);
    clear_ch_status(0);
  endtask
endclass

//------------------------------------------------------------------------------
// 5) WRAP : XTYPE=wrap (010) - dia chi nguon quay vong (FIFO-style region)
//------------------------------------------------------------------------------
class dma350_vseq_wrap extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_wrap)
  function new(string name="dma350_vseq_wrap"); super.new(name); endfunction

  virtual task body();
    super.body();
    apb_write(ch_addr(0,O_SRCADDR),  32'h0000_6000);
    apb_write(ch_addr(0,O_SRCADDRHI),32'h0);
    apb_write(ch_addr(0,O_DESADDR),  32'h0000_7000);
    apb_write(ch_addr(0,O_DESADDRHI),32'h0);
    apb_write(ch_addr(0,O_XSIZE),    {16'd16, 16'd16});
    apb_write(ch_addr(0,O_XADDRINC), 32'h0001_0001);
    // TRANSIZE=word, XTYPE=wrap(010), DONETYPE=end-of-command
    apb_write(ch_addr(0,O_CTRL), (32'h1<<21) | (32'h2<<9) | 32'h2);
    apb_write(ch_addr(0,O_INTREN), 32'h3);
    enable_ch(0);
    wait_ch_done(0);
    clear_ch_status(0);
  endtask
endclass

//------------------------------------------------------------------------------
// 6) Multi-channel : 4 channel copy song song, vung dia chi tach biet
//------------------------------------------------------------------------------
class dma350_vseq_multi_channel extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_multi_channel)
  int unsigned num_ch = 4;
  function new(string name="dma350_vseq_multi_channel"); super.new(name); endfunction

  virtual task body();
    super.body();
    for (int ch = 0; ch < num_ch; ch++)
      cfg_ch_1d(.ch(ch), .src(32'h0001_0000 + ch*32'h1000),
                         .des(32'h0002_0000 + ch*32'h1000), .xsize(8));
    for (int ch = 0; ch < num_ch; ch++)
      enable_ch(ch);
    for (int ch = 0; ch < num_ch; ch++) begin
      wait_ch_done(ch);
      clear_ch_status(ch);
    end
  endtask
endclass

//------------------------------------------------------------------------------
// 7) Stop / Pause : PAUSE -> STAT_PAUSED -> RESUME -> DONE ; lenh 2: STOP
//------------------------------------------------------------------------------
class dma350_vseq_stop_pause extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_stop_pause)
  function new(string name="dma350_vseq_stop_pause"); super.new(name); endfunction

  virtual task body();
    bit [31:0] st;
    super.body();

    // ---- lenh 1: copy dai, pause giua chung roi resume ----
    cfg_ch_1d(.ch(0), .src(32'h0000_8000), .des(32'h0000_9000), .xsize(64));
    enable_ch(0);
    apb_write(ch_addr(0,O_CMD), 32'h1 << B_PAUSE);
    wait_ch_bit(0, S_PAUSED, "PAUSED");
    apb_write(ch_addr(0,O_CMD), 32'h1 << B_RESUME);
    wait_ch_done(0);
    clear_ch_status(0);

    // ---- lenh 2: copy dai, stop giua chung ----
    cfg_ch_1d(.ch(0), .src(32'h0000_A000), .des(32'h0000_B000), .xsize(64));
    enable_ch(0);
    apb_write(ch_addr(0,O_CMD), 32'h1 << B_STOP);
    wait_ch_bit(0, S_STOPPED, "STOPPED");
    clear_ch_status(0);
  endtask
endclass

//------------------------------------------------------------------------------
// 8) All-channel stop/pause qua Status/Control agent (4-phase handshake pin)
//------------------------------------------------------------------------------
class dma350_vseq_allch_stop_pause extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_allch_stop_pause)
  function new(string name="dma350_vseq_allch_stop_pause"); super.new(name); endfunction

  virtual task body();
    super.body();

    // chay 2 channel de stop/pause co doi tuong tac dong
    cfg_ch_1d(.ch(0), .src(32'h0003_0000), .des(32'h0003_4000), .xsize(64));
    cfg_ch_1d(.ch(1), .src(32'h0003_8000), .des(32'h0003_C000), .xsize(64));
    enable_ch(0);
    enable_ch(1);

    // allch PAUSE (nonsec) -> DUT keo ack; sau do allch STOP
    begin
      dma350_sc_pause_seq ps = dma350_sc_pause_seq::type_id::create("allch_pause");
      ps.start(p_sequencer.sc_seqr_h);
    end
    begin
      dma350_sc_stop_seq ss = dma350_sc_stop_seq::type_id::create("allch_stop");
      ss.start(p_sequencer.sc_seqr_h);
    end

    wait_ch_bit(0, S_STOPPED, "STOPPED(allch)");
    wait_ch_bit(1, S_STOPPED, "STOPPED(allch)");
    clear_ch_status(0);
    clear_ch_status(1);
  endtask
endclass

//------------------------------------------------------------------------------
// 9) Low-power : Q-channel quiesce/wake + P-channel khi IDLE; thu khi BUSY
//    (scoreboard process_lpi kiem: low-power ACCEPT khi busy = loi)
//------------------------------------------------------------------------------
class dma350_vseq_lowpower extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_lowpower)
  function new(string name="dma350_vseq_lowpower"); super.new(name); endfunction

  virtual task body();
    super.body();

    // ---- idle: quiesce/wake phai duoc chap nhan ----
    begin
      crlp_qch_cycle_seq q = crlp_qch_cycle_seq::type_id::create("qch_idle");
      q.start(p_sequencer.crlp_seqr_h);
    end

    // ---- busy: bat 1 copy dai roi xin quiesce (mong doi DENY) ----
    cfg_ch_1d(.ch(0), .src(32'h0004_0000), .des(32'h0004_4000), .xsize(64));
    enable_ch(0);
    begin
      crlp_qch_cycle_seq q = crlp_qch_cycle_seq::type_id::create("qch_busy");
      q.start(p_sequencer.crlp_seqr_h);
    end
    wait_ch_done(0);
    clear_ch_status(0);

    // ---- P-channel ve ON (luon accept) ----
    begin
      crlp_pch_seq p = crlp_pch_seq::type_id::create("pch_on");
      if (!p.randomize() with { target_state == PSTATE_ON_FULL; })
        `uvm_error(get_type_name(), "randomize pch failed")
      p.start(p_sequencer.crlp_seqr_h);
    end
  endtask
endclass

//------------------------------------------------------------------------------
// 10) GPO : GPOEN0/GPOVAL0 + USEGPO, readback GPOREAD0; monitor sc doi chieu
//------------------------------------------------------------------------------
class dma350_vseq_gpo extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_gpo)
  function new(string name="dma350_vseq_gpo"); super.new(name); endfunction

  virtual task body();
    super.body();

    apb_write(ch_addr(0,O_GPOEN0),  32'h0000_000F);   // GPO_WIDTH=4 build nay
    apb_write(ch_addr(0,O_GPOVAL0), 32'h0000_000A);
    apb_check(ch_addr(0,O_GPOEN0),  32'h0000_000F, 32'h0000_000F);
    apb_check(ch_addr(0,O_GPOVAL0), 32'h0000_000A, 32'h0000_000F);

    // chay 1 lenh nho voi USEGPO=1 de gpo_ch duoc lai gia tri GPOVAL0
    apb_write(ch_addr(0,O_SRCADDR),  32'h0005_0000);
    apb_write(ch_addr(0,O_SRCADDRHI),32'h0);
    apb_write(ch_addr(0,O_DESADDR),  32'h0005_4000);
    apb_write(ch_addr(0,O_DESADDRHI),32'h0);
    apb_write(ch_addr(0,O_XSIZE),    {16'd4, 16'd4});
    apb_write(ch_addr(0,O_XADDRINC), 32'h0001_0001);
    // TRANSIZE=word, XTYPE=cont, DONETYPE=end-of-cmd, USEGPO(bit28)
    apb_write(ch_addr(0,O_CTRL), (32'h1<<28) | (32'h1<<21) | (32'h1<<9) | 32'h2);
    apb_write(ch_addr(0,O_INTREN), 32'h3);
    enable_ch(0);
    wait_ch_done(0);

    // GPOREAD0 phai phan anh gia tri dang lai
    apb_check(ch_addr(0,O_GPOREAD0), 32'h0000_000A, 32'h0000_000F);
    clear_ch_status(0);
  endtask
endclass

`endif // DMA350_VSEQ_LIB_SV
