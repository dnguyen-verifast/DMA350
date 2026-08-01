//==============================================================================
// dma350_vseq_1d_single_base.sv
//------------------------------------------------------------------------------
// Base cho bo test 1D single theo TRM 5.2.2 "List of cases for 1D WRAP".
// 7 kich ban (to hop SRCXSIZE/DESXSIZE + DESXADDRINC) x 3 XTYPE = 21 vseq con;
// moi vseq con chi set knob trong new() roi goi run_1d().
//
// Ma hoa thanh ghi (theo RTL dma350_ch_regs.sv):
//   CH_XSIZE    : [15:0]=SRCXSIZE , [31:16]=DESXSIZE   (prdata = {desxs_lo, srcxs_lo})
//   CH_XADDRINC : [15:0]=SRCXADDRINC , [31:16]=DESXADDRINC
//   CH_CTRL     : [2:0]=TRANSIZE , [11:9]=XTYPE , [23:21]=DONETYPE
//                 XTYPE: 001=continue 010=wrap 011=fill
//
// Knob kiem tra:
//   expect_idle      : khong co read/write nao du kien -> chi soi STATUS/no-ERR
//   chk_src_drained  : ket thuc phai co SRCXSIZE == 0
//   chk_des_drained  : ket thuc phai co DESXSIZE == 0
// Viec doi chieu burst/du lieu tren bus do dma350_scoreboard lo.
//==============================================================================
`ifndef DMA350_VSEQ_1D_SINGLE_BASE_SV
`define DMA350_VSEQ_1D_SINGLE_BASE_SV

class dma350_vseq_1d_single_base extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_1d_single_base)

  // XTYPE (CH_CTRL[11:9])
  localparam bit [2:0] XT_CONT = 3'b001,
                       XT_WRAP = 3'b010,
                       XT_FILL = 3'b011;

  // ---- knob cau hinh ----
  int unsigned src_xsize    = 0;
  int unsigned des_xsize    = 0;
  int          src_xaddrinc = 1;
  int          des_xaddrinc = 1;
  bit [2:0]    xtype        = XT_CONT;
  bit [2:0]    transize     = 3'd2;            // word (4B)
  bit [31:0]   fillval      = 32'hCAFE_F00D;
  bit [31:0]   src_addr     = 32'h0000_1000;
  bit [31:0]   des_addr     = 32'h0000_2000;

  // ---- knob kiem tra ----
  bit expect_idle     = 0;
  bit chk_src_drained = 0;
  bit chk_des_drained = 0;

  function new(string name = "dma350_vseq_1d_single_base");
    super.new(name);
  endfunction

  //---------------------------------------------------------------------------
  // Cau hinh 1 lenh 1D theo cac knob o tren
  //---------------------------------------------------------------------------
  virtual task cfg_1d(int ch = 0);
    apb_write(ch_addr(ch,O_SRCADDR),   src_addr);
    apb_write(ch_addr(ch,O_SRCADDRHI), 32'h0);
    apb_write(ch_addr(ch,O_DESADDR),   des_addr);
    apb_write(ch_addr(ch,O_DESADDRHI), 32'h0);
    // {DESXSIZE, SRCXSIZE}
    apb_write(ch_addr(ch,O_XSIZE),     {des_xsize[15:0], src_xsize[15:0]});
    // {DESXADDRINC, SRCXADDRINC}
    apb_write(ch_addr(ch,O_XADDRINC),  {des_xaddrinc[15:0], src_xaddrinc[15:0]});
    apb_write(ch_addr(ch,O_FILLVAL),   fillval);
    apb_write(ch_addr(ch,O_YSIZE),     32'h0);   // 1D thuan: khong dung 2D
    // DONETYPE=end-of-command | XTYPE | TRANSIZE
    apb_write(ch_addr(ch,O_CTRL),
              (32'h1 << 21) | ({29'b0, xtype} << 9) | {29'b0, transize});
    apb_write(ch_addr(ch,O_INTREN),    32'h3);   // IE_DONE | IE_ERR

    `uvm_info(get_type_name(), $sformatf(
      "CFG 1D: SRCXSIZE=%0d DESXSIZE=%0d SRCXADDRINC=%0d DESXADDRINC=%0d XTYPE=%0b",
      src_xsize, des_xsize, src_xaddrinc, des_xaddrinc, xtype), UVM_LOW)
  endtask

  //---------------------------------------------------------------------------
  // Chay 1 lenh + doi chieu trang thai ket thuc
  //---------------------------------------------------------------------------
  virtual task run_1d(int ch = 0);
    bit [31:0] st, xs, sa, da;

    cfg_1d(ch);
    enable_ch(ch);

    if (expect_idle) begin
      // Khong du kien co transfer nao: cho mot khoang (poll STATUS cho ton
      // thoi gian) roi kiem tra khong co loi. Bit DONE co the len hoac khong
      // tuy cach RTL ket thuc lenh rong -> chi LOG, khong ep.
      repeat (20) apb_read(ch_addr(ch,O_STATUS), st);
      if (st[S_ERR]) begin
        bit [31:0] ei;
        apb_read(ch_addr(ch,O_ERRINFO), ei);
        `uvm_error(get_type_name(), $sformatf(
          "CH%0d khong du kien transfer nhung co STAT_ERR (STATUS=0x%08h ERRINFO=0x%08h)",
          ch, st, ei))
      end
      `uvm_info(get_type_name(), $sformatf(
        "CH%0d khong co transfer du kien; STATUS=0x%08h (DONE=%0b)",
        ch, st, st[S_DONE]), UVM_LOW)
    end
    else begin
      wait_ch_done(ch);
    end

    // Live counter cuoi lenh
    apb_read(ch_addr(ch,O_XSIZE),   xs);
    apb_read(ch_addr(ch,O_SRCADDR), sa);
    apb_read(ch_addr(ch,O_DESADDR), da);
    `uvm_info(get_type_name(), $sformatf(
      "CH%0d ket thuc: SRCXSIZE=%0d DESXSIZE=%0d SRCADDR=0x%08h DESADDR=0x%08h",
      ch, xs[15:0], xs[31:16], sa, da), UVM_LOW)

    if (chk_src_drained && xs[15:0] !== 16'd0)
      `uvm_error(get_type_name(), $sformatf(
        "CH%0d mong doi SRCXSIZE=0 khi ket thuc, doc duoc %0d", ch, xs[15:0]))
    if (chk_des_drained && xs[31:16] !== 16'd0)
      `uvm_error(get_type_name(), $sformatf(
        "CH%0d mong doi DESXSIZE=0 khi ket thuc, doc duoc %0d", ch, xs[31:16]))

    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_1d_single_base

`endif // DMA350_VSEQ_1D_SINGLE_BASE_SV
