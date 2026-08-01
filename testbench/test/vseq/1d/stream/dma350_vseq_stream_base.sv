//==============================================================================
// dma350_vseq_stream_base.sv
//------------------------------------------------------------------------------
// Base cho bo test STREAM MODE (TRM 5.5 "AXI4 stream operation") - kenh don CH0.
//
// LUONG DU LIEU stream (RTL): khi CH_CTRL.USESTREAM=1
//   - phia DOC : DMA doc nguon tren AXI5 (SRCXSIZE) roi day ra str_out (VIP slave
//                axis nhan, luon-san-sang tu start_responders()).
//   - phia GHI : nhan str_in (VIP master axis lai vao) roi DMA ghi dich tren AXI5
//                (DESXSIZE). Lenh ket thuc khi nhan TLAST tren str_in.
//
// 4 CHE DO (nhu bang anh):
//   No stream        : USESTREAM=0            - mem-to-mem thuong (src_n=des_n)
//   Stream-out only  : USESTREAM=1 src_n=N des_n=0 - doc AXI -> str_out (khong ghi AXI)
//   Stream-in only   : USESTREAM=1 src_n=0 des_n=N - str_in -> ghi AXI (khong doc AXI)
//   Stream-in + out  : USESTREAM=1 src_n=N des_n=N - doc AXI -> str_out; str_in -> ghi AXI
//
// LUU Y RTL: model nay KHONG phan biet STREAMTYPE (CH_STREAMINTCFG bi bo qua o
// loi); che do duoc quyet dinh boi SRCXSIZE/DESXSIZE (co doc/ghi AXI hay khong).
// Ta VAN ghi STREAMTYPE dung theo che do de kiem tra field + doc lai.
//
// str_in duoc lai bang axis_master_packet_seq (N beat, TLAST o beat cuoi) tren
// p_sequencer.axis_mst_seqr_h. str_out do VIP slave (axis_slv_seqr_h) hung.
//==============================================================================
`ifndef DMA350_VSEQ_STREAM_BASE_SV
`define DMA350_VSEQ_STREAM_BASE_SV

class dma350_vseq_stream_base extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_stream_base)

  // STREAMTYPE (CH_STREAMINTCFG[10:9]) - theo TRM 6.5.1.25
  localparam bit [1:0] ST_IN_OUT   = 2'b00,   // Stream in and out
                       ST_OUT_ONLY = 2'b01,   // Stream out only
                       ST_IN_ONLY  = 2'b10;   // Stream in only

  localparam bit [7:0] O_STREAMINTCFG = 8'h68;

  // ---- knob ----
  int unsigned ch        = 0;
  bit          use_stream = 1;
  bit [1:0]    streamtype = ST_IN_OUT;
  bit [31:0]   src_addr   = 32'h0001_0000;
  bit [31:0]   des_addr   = 32'h0002_0000;
  int unsigned src_n      = 8;               // SRCXSIZE (element)
  int unsigned des_n      = 8;               // DESXSIZE (element)
  bit [2:0]    transize   = 3'd2;            // word (4B) - khop be rong stream 32-bit
  bit          drive_in   = 1;               // lai str_in (can khi phia ghi lay tu stream)
  int unsigned in_beats   = 8;               // so beat str_in (= des_n cho in-only/in+out)

  function new(string name = "dma350_vseq_stream_base");
    super.new(name);
  endfunction

  //---------------------------------------------------------------------------
  // Cau hinh channel cho stream
  //---------------------------------------------------------------------------
  virtual task cfg_stream_ch();
    bit [31:0] ctrl;
    apb_write(ch_addr(ch,O_SRCADDR),   src_addr);
    apb_write(ch_addr(ch,O_SRCADDRHI), 32'h0);
    apb_write(ch_addr(ch,O_DESADDR),   des_addr);
    apb_write(ch_addr(ch,O_DESADDRHI), 32'h0);
    apb_write(ch_addr(ch,O_XSIZE),     {des_n[15:0], src_n[15:0]});
    apb_write(ch_addr(ch,O_XADDRINC),  32'h0001_0001);
    apb_write(ch_addr(ch,O_YSIZE),     32'h0);

    if (use_stream)
      apb_write(ch_addr(ch,O_STREAMINTCFG), {21'h0, streamtype, 9'h0}); // [10:9]=STREAMTYPE

    // CH_CTRL : DONETYPE=end-of-cmd | XTYPE=continue | USESTREAM | TRANSIZE
    ctrl = (32'h1 << 21) | (32'h1 << 9) | {29'b0, transize};
    if (use_stream) ctrl |= (32'h1 << 29);         // CTRL_USESTREAM
    apb_write(ch_addr(ch,O_CTRL),   ctrl);
    apb_write(ch_addr(ch,O_INTREN), 32'h0000_0003);// IE_DONE | IE_ERR

    `uvm_info(get_type_name(), $sformatf(
      "CFG STREAM CH%0d: use_stream=%0b STREAMTYPE=%0b src_n=%0d des_n=%0d drive_in=%0b in_beats=%0d",
      ch, use_stream, streamtype, src_n, des_n, drive_in, in_beats), UVM_LOW)
  endtask

  //---------------------------------------------------------------------------
  // Lai str_in: 1 packet N beat, TLAST o beat cuoi (ket thuc lenh phia ghi).
  //---------------------------------------------------------------------------
  virtual task drive_stream_in(int unsigned n);
    axis_master_packet_seq s = axis_master_packet_seq::type_id::create("str_in_pkt");
    if (p_sequencer.axis_mst_seqr_h == null) begin
      `uvm_error(get_type_name(),
        "axis_mst_seqr_h = null (axis master passive?) - khong lai duoc str_in")
      return;
    end
    if (!s.randomize() with { len == n; })
      `uvm_error(get_type_name(), "randomize axis_master_packet_seq that bai")
    s.start(p_sequencer.axis_mst_seqr_h);
    `uvm_info(get_type_name(), $sformatf("da lai %0d beat str_in (TLAST cuoi)", n), UVM_LOW)
  endtask

  //---------------------------------------------------------------------------
  // body: POR + responder (co axis slave always-ready hung str_out) -> cfg ->
  //       enable -> (lai str_in neu can) -> cho DONE.
  //---------------------------------------------------------------------------
  virtual task body();
    super.body();                 // por + responders (AXI5 + AXIS slave ready)
    cfg_stream_ch();
    enable_ch(ch);
    if (use_stream && drive_in)
      drive_stream_in(in_beats);  // phia ghi cho TLAST tu str_in
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_stream_base

`endif // DMA350_VSEQ_STREAM_BASE_SV
