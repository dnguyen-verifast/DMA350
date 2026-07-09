//==============================================================================
// dma350_vseq_base.sv
//------------------------------------------------------------------------------
// Virtual sequence goc cua DMA-350. Moi vseq test ke thua tu day.
//
// Cung cap:
//   * p_sequencer = dma350_virtual_sequencer (handle toi sequencer moi agent)
//   * por()             : CRLP power-on-reset (start clock + pulse resetn)
//   * start_responders(): fork forever cac slave-response sequence AXI5 M0/M1
//                         + AXIS slave always-ready (DUT khong bi nghet TREADY)
//   * apb_write/apb_read: truy cap thanh ghi qua APB agent
//   * ch_addr()         : dia chi thanh ghi channel (0x1000 + 0x100*ch + off)
//   * cfg_ch_1d()       : cau hinh copy 1D co ban cho 1 channel
//   * enable_ch()/wait_ch_done()/clear_ch_status(): dieu khien + poll STATUS
//
// Ma hoa CH_CTRL (theo RTL dma350_ch_regs):
//   [2:0] TRANSIZE  (010=word 4B)      [11:9]  XTYPE (001=cont 010=wrap 011=fill)
//   [14:12] YTYPE   (001=cont 2D)      [23:21] DONETYPE (001=end-of-cmd)
//   [28] USEGPO     [29] USESTREAM
//==============================================================================
`ifndef DMA350_VSEQ_BASE_SV
`define DMA350_VSEQ_BASE_SV

class dma350_vseq_base extends uvm_sequence;
  `uvm_object_utils(dma350_vseq_base)
  `uvm_declare_p_sequencer(dma350_virtual_sequencer)

  // ---- offset thanh ghi channel ----
  localparam bit [7:0] O_CMD=8'h00, O_STATUS=8'h04, O_INTREN=8'h08, O_CTRL=8'h0C,
                       O_SRCADDR=8'h10, O_SRCADDRHI=8'h14, O_DESADDR=8'h18,
                       O_DESADDRHI=8'h1C, O_XSIZE=8'h20, O_XSIZEHI=8'h24,
                       O_SRCTRANSCFG=8'h28, O_DESTRANSCFG=8'h2C,
                       O_XADDRINC=8'h30, O_YADDRSTRIDE=8'h34, O_FILLVAL=8'h38,
                       O_YSIZE=8'h3C, O_GPOEN0=8'h58, O_GPOVAL0=8'h60,
                       O_AUTOCFG=8'h74, O_GPOREAD0=8'h80, O_ERRINFO=8'h90;

  // ---- bit CH_CMD / CH_STATUS ----
  localparam int B_ENABLE=0, B_CLEAR=1, B_DISABLE=2, B_STOP=3, B_PAUSE=4, B_RESUME=5;
  localparam int S_DONE=16, S_ERR=17, S_STOPPED=18, S_DISABLED=19, S_PAUSED=20;

  // timeout poll (so lan doc STATUS)
  int unsigned poll_limit = 2000;

  function new(string name = "dma350_vseq_base");
    super.new(name);
  endfunction

  //---------------------------------------------------------------------------
  // Dia chi thanh ghi: channel frame o 0x1000 + 0x100*ch (TRM 6.3)
  //---------------------------------------------------------------------------
  function bit [31:0] ch_addr(int ch, bit [7:0] off);
    return 32'h1000 + (ch << 8) + off;
  endfunction

  //---------------------------------------------------------------------------
  // CRLP power-on-reset : PHAI goi dau moi test (clock do CRLP driver sinh)
  //---------------------------------------------------------------------------
  virtual task por();
    crlp_por_seq s = crlp_por_seq::type_id::create("por");
    s.start(p_sequencer.crlp_seqr_h);
  endtask

  //---------------------------------------------------------------------------
  // Responder chay nen: AXI5 slave M0/M1 (tra R data + B resp) va AXIS slave
  // always-ready. fork/join_none - song den het test (phase end se kill).
  //---------------------------------------------------------------------------
  virtual task start_responders();
    fork
      forever begin
        axi5_slave_read_seq s = axi5_slave_read_seq::type_id::create("m0_rd");
        s.start(p_sequencer.axi5_slv0_read_seqr_h);
      end
      forever begin
        axi5_slave_write_seq s = axi5_slave_write_seq::type_id::create("m0_wr");
        s.start(p_sequencer.axi5_slv0_write_seqr_h);
      end
      forever begin
        axi5_slave_read_seq s = axi5_slave_read_seq::type_id::create("m1_rd");
        s.start(p_sequencer.axi5_slv1_read_seqr_h);
      end
      forever begin
        axi5_slave_write_seq s = axi5_slave_write_seq::type_id::create("m1_wr");
        s.start(p_sequencer.axi5_slv1_write_seqr_h);
      end
      forever begin
        axis_slave_always_ready_seq s =
          axis_slave_always_ready_seq::type_id::create("axis_rdy");
        s.start(p_sequencer.axis_slv_seqr_h);
      end
    join_none
  endtask

  //---------------------------------------------------------------------------
  // Truy cap APB
  //---------------------------------------------------------------------------
  virtual task apb_write(bit [31:0] addr, bit [31:0] data);
    dma350_apb_write_seq s = dma350_apb_write_seq::type_id::create("apb_wr");
    s.addr = addr; s.data = data;
    s.start(p_sequencer.apb_seqr_h);
  endtask

  virtual task apb_read(bit [31:0] addr, output bit [31:0] data);
    dma350_apb_read_seq s = dma350_apb_read_seq::type_id::create("apb_rd");
    s.addr = addr;
    s.start(p_sequencer.apb_seqr_h);
    data = s.data;
  endtask

  // doc + so voi gia tri mong doi (mask bit quan tam)
  virtual task apb_check(bit [31:0] addr, bit [31:0] exp, bit [31:0] mask = '1);
    bit [31:0] d;
    apb_read(addr, d);
    if ((d & mask) !== (exp & mask))
      `uvm_error(get_type_name(), $sformatf(
        "READBACK MISMATCH @0x%04h : doc=0x%08h mong doi=0x%08h (mask=0x%08h)",
        addr, d, exp, mask))
  endtask

  //---------------------------------------------------------------------------
  // Cau hinh copy 1D: xsize element x (1<<transize) byte, dia chi tang dan
  //---------------------------------------------------------------------------
  virtual task cfg_ch(int ch, bit [31:0] src, bit [31:0] des,
                         int unsigned xsize, bit [2:0] transize = 3'd2);
    apb_write(ch_addr(ch,O_SRCADDR),  src);
    apb_write(ch_addr(ch,O_SRCADDRHI),32'h0);
    apb_write(ch_addr(ch,O_DESADDR),  des);
    apb_write(ch_addr(ch,O_DESADDRHI),32'h0);
    apb_write(ch_addr(ch,O_XSIZE),    {xsize[15:0], xsize[15:0]});
    apb_write(ch_addr(ch,O_XADDRINC), 32'h0001_0001);   // src/des +1 element
    // TRANSIZE + XTYPE=continue + DONETYPE=end-of-command
    apb_write(ch_addr(ch,O_CTRL), (32'h1 << 21) | (32'h1 << 9) | {29'b0, transize});
    apb_write(ch_addr(ch,O_INTREN), 32'h0000_0003);      // IE_DONE | IE_ERR
  endtask

  //---------------------------------------------------------------------------
  // Enable / poll done / W1C status
  //---------------------------------------------------------------------------
  virtual task enable_ch(int ch);
    apb_write(ch_addr(ch,O_CMD), 32'h1 << B_ENABLE);
  endtask

  virtual task wait_ch_bit(int ch, int bitpos, string what);
    bit [31:0] st;
    repeat (poll_limit) begin
      apb_read(ch_addr(ch,O_STATUS), st);
      if (st[S_ERR]) begin
        bit [31:0] ei;
        apb_read(ch_addr(ch,O_ERRINFO), ei);
        `uvm_error(get_type_name(), $sformatf(
          "CH%0d STAT_ERR khi cho %s (STATUS=0x%08h ERRINFO=0x%08h)", ch, what, st, ei))
        return;
      end
      if (st[bitpos]) begin
        `uvm_info(get_type_name(), $sformatf("CH%0d %s (STATUS=0x%08h)", ch, what, st), UVM_LOW)
        return;
      end
    end
    `uvm_error(get_type_name(), $sformatf("CH%0d TIMEOUT cho %s", ch, what))
  endtask

  virtual task wait_ch_done(int ch);
    wait_ch_bit(ch, S_DONE, "DONE");
  endtask

  virtual task clear_ch_status(int ch);
    // W1C cac bit ket thuc
    apb_write(ch_addr(ch,O_STATUS),
              (32'h1<<S_DONE)|(32'h1<<S_ERR)|(32'h1<<S_STOPPED)|(32'h1<<S_DISABLED));
  endtask

  //---------------------------------------------------------------------------
  // body mac dinh: POR + responder. Vseq con: super.body() roi lam viec chinh.
  //---------------------------------------------------------------------------
  virtual task body();
    por();
    start_responders();
    #100ns;   // on dinh sau reset (APB driver tu dong doi rstn truoc item dau)
  endtask

endclass : dma350_vseq_base

`endif // DMA350_VSEQ_BASE_SV
