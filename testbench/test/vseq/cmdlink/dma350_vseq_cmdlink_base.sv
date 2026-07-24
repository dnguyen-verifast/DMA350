//==============================================================================
// dma350_vseq_cmdlink_base.sv
//------------------------------------------------------------------------------
// Base cho bo test COMMAND LINKING (TRM 5.7 "Command linking") - kenh don CH0.
//
// HAI LUONG KHOI DONG chuoi lenh (mode):
//   MODE_APB  : lenh #0 cau hinh TRUC TIEP qua APB, chay xong thi CH_LINKADDR
//               tro toi descriptor #0 -> DMAC NAP LENH TIEP THEO QUA AXI.
//   MODE_BOOT : autoboot - boot_addr tro toi descriptor #0; DMAC tu nap lenh dau
//               vao CH0 va chay ngay sau reset, roi command-link tiep (tat ca qua
//               AXI). Lenh boot dau tien PHAI REGCLEAR (thanh ghi ve mac dinh).
//
// DESCRIPTOR nap vao dma350_cmdlink_mem_pkg::cmdlink_mem (backdoor). Khi DUT doc
// (arcmdlink=1) tren AXI5 M0, hook trong axi5_slave_driver_proxy tra ve dung
// byte da nap (can +define+DMA350_CMDLINK_HOOK). Nho vay ta kiem soat duoc HEADER
// va gia tri tung lenh -> "xem no nap dung khong".
//
// HEADER (Table 5-12): tu 32-bit dau moi descriptor, bit i = 1 nghia la thanh
// ghi thu i can update; cac word tiep theo la GIA TRI, xep theo thu tu bit tang
// dan (LSB->MSB). Bit0 REGCLEAR khong co word gia tri di kem.
//
// BO XAY DUNG descriptor (dung trong program_descriptors() cua vseq con):
//   cmd_slot(i)  : dat con tro ghi toi slot lenh thu i (cach nhau CMD_STRIDE)
//   cmd_begin(regclear) : bat dau 1 lenh
//   cmd_set(HDR_x, val) : chon update thanh ghi x = val
//   cmd_link(i)  / cmd_end() : dat CH_LINKADDR -> lenh i (LINKADDREN=1) / ket thuc
//   cmd_emit()   : ghi header + payload vao desc mem
//
// HOAN THANH CHUOI: CH_CMD.ENABLECMD (bit0) tu dong ve 0 khi CA CHUOI xong
//   (TRM 6.5.1.1). wait_chain_done() poll bit nay + soi STAT_ERR.
//==============================================================================
`ifndef DMA350_VSEQ_CMDLINK_BASE_SV
`define DMA350_VSEQ_CMDLINK_BASE_SV

class dma350_vseq_cmdlink_base extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_cmdlink_base)

  //--------------------------------------------------------------------------
  // Vi tri bit HEADER (Table 5-12), LINKADDREN, TRANSCFG_DEFAULT, CMDLINK_BASE,
  // SRC_BUF_0/DES_BUF_0 ... : DUNG SAN tu dma350_cmdlink_mem_pkg (da import o
  // dma350_test_pkg) -> KHONG khai bao lai o day. Bo nho descriptor nap tay
  // cung o package do: cmdlink_mem_clear/write_word/has/get.
  //--------------------------------------------------------------------------

  //--------------------------------------------------------------------------
  // Offset thanh ghi bo sung (ngoai cac offset da co o dma350_vseq_base)
  //--------------------------------------------------------------------------
  localparam bit [7:0] O_LINKATTR = 8'h70, O_LINKADDR = 8'h78, O_LINKADDRHI = 8'h7C;

  //--------------------------------------------------------------------------
  // MODE khoi dong
  //--------------------------------------------------------------------------
  typedef enum { MODE_APB, MODE_BOOT } cmdlink_mode_e;
  cmdlink_mode_e mode = MODE_APB;

  //--------------------------------------------------------------------------
  // Bo tri descriptor trong bo nho (cac slot cach deu, du rong cho 1 lenh bat ky)
  //   DESC_BASE   : = CMDLINK_BASE (0x2000) - khong dung chung vung du lieu
  //   CMD_STRIDE  : 0x40 byte = 16 word -> du cho header + toi da payload
  //--------------------------------------------------------------------------
  localparam bit [31:0] DESC_BASE  = CMDLINK_BASE[31:0];   // tu package
  localparam bit [31:0] CMD_STRIDE = 32'h0000_0040;

  // Vung du lieu copy (noi dung nguon la ngau nhien - scoreboard tu doi chieu R->W)
  bit [31:0] src_addr = SRC_BUF_0;         // tu package (0x0001_0000)
  bit [31:0] des_addr = DES_BUF_0;         // tu package (0x0002_0000)
  int unsigned xsize  = 16;
  bit [2:0]  transize = 3'd2;              // word (4B)

  function new(string name="dma350_vseq_cmdlink_base");
    super.new(name);
  endfunction
  
  function bit [31:0] cmd_addr(int idx);
    return DESC_BASE + idx*CMD_STRIDE;
  endfunction

  //--------------------------------------------------------------------------
  // BO XAY DUNG descriptor
  //--------------------------------------------------------------------------
  bit [31:0]  dp;                 // con tro ghi hien tai
  bit         fld_pres [32];      // field nao co mat trong lenh dang xay
  bit [31:0]  fld_val  [32];      // gia tri tuong ung

  function void cmd_slot(int idx);
    dp = cmd_addr(idx);
  endfunction

  function void cmd_begin(bit regclear = 0);
    foreach (fld_pres[i]) fld_pres[i] = 1'b0;
    if (regclear) fld_pres[HDR_REGCLEAR] = 1'b1;  // bit0: co trong header, khong payload
  endfunction

  function void cmd_set(int bitpos, bit [31:0] val);
    fld_pres[bitpos] = 1'b1;
    fld_val [bitpos] = val;
  endfunction

  // Lenh ket thuc bang cach dat CH_LINKADDR -> lenh 'idx' (LINKADDREN=1).
  function void cmd_link(int idx);
    cmd_set(HDR_LINKADDR, cmd_addr(idx) | LINKADDREN);
  endfunction

  // Lenh CUOI: LINKADDR = 0 -> LINKADDREN=0 -> ket thuc chuoi.
  function void cmd_end();
    cmd_set(HDR_LINKADDR, 32'h0);
  endfunction

  // Ghi header + payload vao desc mem tai dp; tu dong tang dp.
  function void cmd_emit();
    bit [31:0] hdr   = 32'h0;
    bit [31:0] start = dp;
    for (int i = 0; i < 32; i++) if (fld_pres[i]) hdr[i] = 1'b1;
    cmdlink_mem_write_word(dp, hdr);  dp += 4;
    // payload theo thu tu bit tang dan; bit0 (REGCLEAR) KHONG co payload word
    for (int i = 2; i < 32; i++)
      if (fld_pres[i]) begin
        cmdlink_mem_write_word(dp, fld_val[i]);
        dp += 4;
      end
    `uvm_info(get_type_name(), $sformatf(
      "EMIT descriptor @0x%0h HEADER=0x%08h (%0d payload word)",
      start, hdr, (dp - start)/4 - 1), UVM_LOW)
  endfunction

  //--------------------------------------------------------------------------
  // Gia tri CH_CTRL 1D: DONETYPE=001(end-of-cmd) | XTYPE(cont) | TRANSIZE
  //--------------------------------------------------------------------------
  function bit [31:0] ctrl_1d(bit [2:0] tsize = 3'd2, bit [2:0] xtype = 3'b001);
    return (32'h1 << 21) | ({29'b0, xtype} << 9) | {29'b0, tsize};
  endfunction

  // TRANSCFG_DEFAULT (0x000F_0400) : dung tu dma350_cmdlink_mem_pkg

  //--------------------------------------------------------------------------
  // Descriptor cua tung test: vseq con OVERRIDE ham nay.
  // Xay cac lenh se duoc NAP QUA AXI (command-link), bat dau tu slot 0.
  //--------------------------------------------------------------------------
  virtual function void program_descriptors();
    // Mac dinh: chuoi 2 lenh don gian, header khac nhau.
    // Lenh 0 (nap qua AXI): doi CTRL/SRC/DES/XSIZE, link -> lenh 1.
    cmd_slot(0); cmd_begin(0);
      cmd_set(HDR_CTRL,    ctrl_1d(transize));
      cmd_set(HDR_SRCADDR, src_addr + 32'h1000);
      cmd_set(HDR_DESADDR, des_addr + 32'h1000);
      cmd_set(HDR_XSIZE,   {16'd8, 16'd8});
      cmd_link(1);
    cmd_emit();
    // Lenh 1 (nap qua AXI): chi doi DESADDR + XSIZE, ket thuc chuoi.
    cmd_slot(1); cmd_begin(0);
      cmd_set(HDR_DESADDR, des_addr + 32'h2000);
      cmd_set(HDR_XSIZE,   {16'd4, 16'd4});
      cmd_end();
    cmd_emit();
  endfunction

  //--------------------------------------------------------------------------
  // Cau hinh LENH #0 truc tiep qua APB (chi dung o MODE_APB).
  // Mot copy 1D chuan, sau do CH_LINKADDR -> descriptor #0 (nap qua AXI).
  //--------------------------------------------------------------------------
  virtual task cfg_apb_cmd0();
    apb_write(ch_addr(ch,O_SRCADDR),   src_addr);
    apb_write(ch_addr(ch,O_SRCADDRHI), 32'h0);
    apb_write(ch_addr(ch,O_DESADDR),   des_addr);
    apb_write(ch_addr(ch,O_DESADDRHI), 32'h0);
    apb_write(ch_addr(ch,O_XSIZE),     {xsize[15:0], xsize[15:0]});
    apb_write(ch_addr(ch,O_XADDRINC),  32'h0001_0001);
    apb_write(ch_addr(ch,O_YSIZE),     32'h0);
    apb_write(ch_addr(ch,O_SRCTRANSCFG), TRANSCFG_DEFAULT);
    apb_write(ch_addr(ch,O_DESTRANSCFG), TRANSCFG_DEFAULT);
    apb_write(ch_addr(ch,O_CTRL),      ctrl_1d(transize));
    apb_write(ch_addr(ch,O_INTREN),    32'h0000_0003);       // IE_DONE | IE_ERR
    // Lien ket toi descriptor dau tien (nap qua AXI)
    apb_write(ch_addr(ch,O_LINKADDR),  cmd_addr(0) | LINKADDREN);
  endtask

  int unsigned ch = 0;

  //--------------------------------------------------------------------------
  // Cho CA CHUOI lenh xong: CH_CMD.ENABLECMD tu ve 0 (TRM 6.5.1.1).
  //--------------------------------------------------------------------------
  virtual task wait_chain_done();
    bit [31:0] cmd, st;
    repeat (poll_limit) begin
      apb_read(ch_addr(ch,O_STATUS), st);
      if (st[S_ERR]) begin
        bit [31:0] ei;
        apb_read(ch_addr(ch,O_ERRINFO), ei);
        `uvm_error(get_type_name(), $sformatf(
          "CH%0d STAT_ERR trong command-link (STATUS=0x%08h ERRINFO=0x%08h)", ch, st, ei))
        return;
      end
      apb_read(ch_addr(ch,O_CMD), cmd);
      if (cmd[B_ENABLE] == 1'b0) begin
        `uvm_info(get_type_name(), $sformatf(
          "CH%0d command-link chain DONE (CH_CMD=0x%08h STATUS=0x%08h)", ch, cmd, st), UVM_LOW)
        return;
      end
    end
    `uvm_error(get_type_name(), $sformatf("CH%0d TIMEOUT cho command-link chain xong", ch))
  endtask

  //--------------------------------------------------------------------------
  // Autoboot: dat boot_addr = descriptor #0, drive boot pin qua reset.
  //--------------------------------------------------------------------------
  virtual task drive_boot(bit [31:0] boot_word_addr);
    boot_directed_seq bs = boot_directed_seq::type_id::create("boot_directed");
    bs.addr = boot_word_addr[31:2];          // boot_addr la [63:2]
    bs.start(p_sequencer.boot_seqr_h);
  endtask

  //--------------------------------------------------------------------------
  // body: nap descriptor -> chay theo mode
  //--------------------------------------------------------------------------
  virtual task body();
    // 1) Nap anh descriptor (backdoor tuc thi)
    cmdlink_mem_clear();
    program_descriptors();

    if (mode == MODE_BOOT) begin
      // Autoboot: responder phai san sang TRUOC khi reset nha (boot fetch xay ra
      // ngay sau reset). Boot seq drive boot pin trong luc reset thap.
      start_responders();
      fork drive_boot(cmd_addr(0)); join_none
      por();                 // clk start + reset pulse -> boot latched -> autoboot
      #200ns;
      wait_chain_done();
    end
    else begin
      // MODE_APB: por + responder chuan, cau hinh lenh #0 qua APB roi enable.
      super.body();          // por + responders + settle
      cfg_apb_cmd0();
      enable_ch(ch);
      wait_chain_done();
    end
  endtask

endclass : dma350_vseq_cmdlink_base

`endif // DMA350_VSEQ_CMDLINK_BASE_SV
