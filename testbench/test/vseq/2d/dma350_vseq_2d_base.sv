//==============================================================================
// dma350_vseq_2d_base.sv
//------------------------------------------------------------------------------
// Base cho bo test 2D (TRM 5.3 "DMAC operation extended commands").
// Cac vseq con chi set knob trong new() roi goi run_2d().
//
// MA HOA THANH GHI (lay tu RTL dma350_ch_regs.sv / dma350_pkg.sv - KHONG doan):
//   CH_XSIZE       [15:0]=SRCXSIZE    [31:16]=DESXSIZE
//   CH_YSIZE       [15:0]=SRCYSIZE    [31:16]=DESYSIZE
//   CH_XADDRINC    [15:0]=SRCXADDRINC [31:16]=DESXADDRINC      (2s complement)
//   CH_YADDRSTRIDE [15:0]=SRCYADDRSTRIDE [31:16]=DESYADDRSTRIDE (2s complement)
//   CH_CTRL        [2:0]=TRANSIZE [11:9]=XTYPE [14:12]=YTYPE
//                  [20:18]=REGRELOADTYPE [23:21]=DONETYPE [24]=DONEPAUSEEN
//                  [25]=USESRCTRIGIN [26]=USEDESTRIGIN [27]=USETRIGOUT
//                  [28]=USEGPO [29]=USESTREAM
//   CH_TMPLTCFG    RTL: srctmpltsize=[4:0], destmpltsize=[20:16]
//
// HAI DIEM RTL KHAC TRM - GHI RO DE KHONG NHAM KHI DEBUG:
//   (1) STRIDE la BYTE. RTL: src_line_base <= src_line_base + sstride_q, voi
//       sstride_q = sign-extend(CH_YADDRSTRIDE[15:0]) -> KHONG nhan 2^TRANSIZE.
//       TRM 6.5.1.14 noi stride tinh theo buoc TRANSIZE. Knob *_ystride o day
//       la GIA TRI THANH GHI (byte theo RTL).
//   (2) CH_TMPLTCFG.SRCTMPLTSIZE: RTL doc [4:0], TRM 6.5.1.17 ghi [12:8].
//       Ta ghi theo RTL de test chay duoc; neu RTL sua theo TRM thi chi can doi
//       ham tmpltcfg() o day.
//
//   (3) *** QUAN TRONG *** RTL KHONG DUNG DESYSIZE.
//       dma350_ch_regs.sv:  assign ysize = ysize_q[15:0];   // = SRCYSIZE
//       CH_YSIZE[31:16] (DESYSIZE) duoc ghi/doc lai duoc nhung KHONG co duong
//       nao dan toi datapath. dma350_channel.sv dung passes = ysize (= SRCYSIZE).
//       Hau qua: toan bo ngu nghia theo chieu Y cua TRM 5.3.2.2 (SRCYSIZE so voi
//       DESYSIZE -> wrap / fill / continue / dung som) HIEN CHUA CO trong RTL.
//       Cac vseq nhom B va cac corner case nhom C phu thuoc DESYSIZE se lech
//       ket qua - day la LO HONG RTL, KHONG phai loi test. Can xac nhan voi
//       thiet ke truoc khi debug tung test.
//
// LUU Y hanh vi 2D cua RTL: nhanh 2D chi bat khi YSIZE (= SRCYSIZE) > 1
// (passes = ysize). YTYPE ghi dung theo spec de kiem tra field + doc lai, nhung
// RTL cung KHONG dung YTYPE de quyet dinh gi (chi XTYPE sinh wrap_en/fill_en).
//
// Knob kiem tra:
//   expect_idle    : khong du kien co transfer -> chi soi khong co STAT_ERR
//   expect_cfg_err : du kien CONFIG ERROR -> phai co STAT_ERR + ERRINFO.CFGERR
//   chk_src_drained / chk_des_drained : cuoi lenh SRCXSIZE / DESXSIZE phai = 0
// Doi chieu burst/du lieu tren bus do dma350_scoreboard lo.
//==============================================================================
`ifndef DMA350_VSEQ_2D_BASE_SV
`define DMA350_VSEQ_2D_BASE_SV

class dma350_vseq_2d_base extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_2d_base)

  // XTYPE (CH_CTRL[11:9]) / YTYPE (CH_CTRL[14:12])
  localparam bit [2:0] XT_DIS  = 3'b000, XT_CONT = 3'b001,
                       XT_WRAP = 3'b010, XT_FILL = 3'b011;
  localparam bit [2:0] YT_DIS  = 3'b000, YT_CONT = 3'b001,
                       YT_WRAP = 3'b010, YT_FILL = 3'b011;

  // Offset bo sung (ngoai cac offset da co o dma350_vseq_base)
  localparam bit [7:0] O_SRCTMPLT = 8'h44, O_DESTMPLT = 8'h48,
                       O_STREAMINTCFG = 8'h68;

  // Bit ERRINFO (RTL dma350_pkg)
  localparam int EI_BUSERR = 0, EI_CFGERR = 1, EI_STREAMERR = 5,
                 EI_REGVALERR = 25, EI_CFGCONFLERR = 26;

  // ---- knob hinh hoc ----
  int unsigned ch        = 0;
  bit [31:0]   src_addr  = 32'h0006_0000;
  bit [31:0]   des_addr  = 32'h0006_8000;
  int unsigned src_xsize = 8;              // element / dong (nguon)
  int unsigned des_xsize = 8;              // element / dong (dich)
  int unsigned src_ysize = 4;              // so dong nguon
  int unsigned des_ysize = 4;              // so dong dich
  int          src_xaddrinc = 1;           // buoc trong dong (element)
  int          des_xaddrinc = 1;
  int          src_ystride  = 'h40;        // buoc giua 2 dong (BYTE - xem (1))
  int          des_ystride  = 'h40;
  bit [2:0]    xtype     = XT_CONT;
  bit [2:0]    ytype     = YT_CONT;
  bit [2:0]    transize  = 3'd2;           // word (4B)
  bit [31:0]   fillval   = 32'hCAFE_F00D;

  // ---- knob template (TRM 5.3.3) ----
  bit [4:0]    srctmpltsize = 5'd0;        // 0 = tat
  bit [4:0]    destmpltsize = 5'd0;
  bit [31:0]   srctmplt     = 32'h0000_0001;  // bit0 co dinh = 1
  bit [31:0]   destmplt     = 32'h0000_0001;

  // ---- knob CH_CTRL phu ----
  bit [2:0]    donetype      = 3'b001;     // end-of-command
  bit [2:0]    regreloadtype = 3'b000;
  bit          donepauseen   = 1'b0;
  bit          use_stream    = 1'b0;
  bit [1:0]    streamtype    = 2'b00;
  bit [31:0]   extra_ctrl    = 32'h0;      // OR them (USE*TRIG / USEGPO ...)

  // ---- knob thuoc tinh bus / autorestart ----
  bit [31:0]   src_transcfg = 32'h000F_0400;
  bit [31:0]   des_transcfg = 32'h000F_0400;
  bit [31:0]   autocfg      = 32'h0;

  // ---- knob kiem tra ----
  bit expect_idle     = 0;
  bit expect_cfg_err  = 0;
  bit chk_src_drained = 0;
  bit chk_des_drained = 0;

  function new(string name = "dma350_vseq_2d_base");
    super.new(name);
  endfunction

  //---------------------------------------------------------------------------
  // Tien ich hinh hoc
  //---------------------------------------------------------------------------
  // So byte du lieu that su cua mot dong (element x co dai element)
  function int unsigned src_line_bytes();
    return src_xsize << transize;
  endfunction
  function int unsigned des_line_bytes();
    return des_xsize << transize;
  endfunction

  // Stride "vua khit" mot dong (frame lien tuc, khong co gap)
  function int src_stride_tight();
    return int'(src_line_bytes());
  endfunction
  function int des_stride_tight();
    return int'(des_line_bytes());
  endfunction

  // CH_CTRL ghep tu cac knob
  function bit [31:0] ctrl_2d();
    bit [31:0] v;
    v = ({29'b0, donetype}      << 21)
      | ({29'b0, regreloadtype} << 18)
      | ({29'b0, ytype}         << 12)
      | ({29'b0, xtype}         <<  9)
      | {29'b0, transize};
    if (donepauseen) v |= (32'h1 << 24);
    if (use_stream)  v |= (32'h1 << 29);
    return v | extra_ctrl;
  endfunction

  // CH_TMPLTCFG theo RTL (xem ghi chu (2) o dau file)
  function bit [31:0] tmpltcfg();
    return ({27'b0, destmpltsize} << 16) | {27'b0, srctmpltsize};
  endfunction

  //---------------------------------------------------------------------------
  // Cau hinh mot lenh 2D theo cac knob
  //---------------------------------------------------------------------------
  virtual task cfg_2d(int c = -1);
    int cc = (c < 0) ? int'(ch) : c;

    apb_write(ch_addr(cc,O_SRCADDR),     src_addr);
    apb_write(ch_addr(cc,O_SRCADDRHI),   32'h0);
    apb_write(ch_addr(cc,O_DESADDR),     des_addr);
    apb_write(ch_addr(cc,O_DESADDRHI),   32'h0);
    apb_write(ch_addr(cc,O_XSIZE),       {des_xsize[15:0], src_xsize[15:0]});
    apb_write(ch_addr(cc,O_YSIZE),       {des_ysize[15:0], src_ysize[15:0]});
    apb_write(ch_addr(cc,O_XADDRINC),    {des_xaddrinc[15:0], src_xaddrinc[15:0]});
    apb_write(ch_addr(cc,O_YADDRSTRIDE), {des_ystride[15:0],  src_ystride[15:0]});
    apb_write(ch_addr(cc,O_FILLVAL),     fillval);
    apb_write(ch_addr(cc,O_TMPLTCFG),    tmpltcfg());
    apb_write(ch_addr(cc,O_SRCTMPLT),    srctmplt);
    apb_write(ch_addr(cc,O_DESTMPLT),    destmplt);
    apb_write(ch_addr(cc,O_SRCTRANSCFG), src_transcfg);
    apb_write(ch_addr(cc,O_DESTRANSCFG), des_transcfg);
    apb_write(ch_addr(cc,O_AUTOCFG),     autocfg);
    if (use_stream)
      apb_write(ch_addr(cc,O_STREAMINTCFG), {21'h0, streamtype, 9'h0});
    apb_write(ch_addr(cc,O_CTRL),        ctrl_2d());
    apb_write(ch_addr(cc,O_INTREN),      32'h0000_0003);   // IE_DONE | IE_ERR

    `uvm_info(get_type_name(), $sformatf(
      "CFG 2D CH%0d: SRC %0dx%0d (inc=%0d stride=%0d) -> DES %0dx%0d (inc=%0d stride=%0d) XTYPE=%03b YTYPE=%03b TRANSIZE=%0d",
      cc, src_xsize, src_ysize, src_xaddrinc, src_ystride,
      des_xsize, des_ysize, des_xaddrinc, des_ystride,
      xtype, ytype, transize), UVM_LOW)
  endtask

  //---------------------------------------------------------------------------
  // Cho CONFIG ERROR (dung cho cac test am)
  //---------------------------------------------------------------------------
  virtual task wait_cfg_err(int c = -1);
    int cc = (c < 0) ? int'(ch) : c;
    bit [31:0] st, ei;
    repeat (poll_limit) begin
      apb_read(ch_addr(cc,O_STATUS), st);
      if (st[S_ERR]) begin
        apb_read(ch_addr(cc,O_ERRINFO), ei);
        if (!ei[EI_CFGERR])
          `uvm_error(get_type_name(), $sformatf(
            "CH%0d co STAT_ERR nhung ERRINFO.CFGERR=0 (ERRINFO=0x%08h) - khong phai config error",
            cc, ei))
        else
          `uvm_info(get_type_name(), $sformatf(
            "CH%0d CONFIG ERROR dung mong doi (ERRINFO=0x%08h REGVALERR=%0b CFGCONFLERR=%0b)",
            cc, ei, ei[EI_REGVALERR], ei[EI_CFGCONFLERR]), UVM_LOW)
        return;
      end
      if (st[S_DONE]) begin
        `uvm_error(get_type_name(), $sformatf(
          "CH%0d mong doi CONFIG ERROR nhung lenh chay xong binh thuong (STATUS=0x%08h)",
          cc, st))
        return;
      end
    end
    `uvm_error(get_type_name(), $sformatf(
      "CH%0d TIMEOUT cho CONFIG ERROR (khong ERR, khong DONE)", cc))
  endtask

  //---------------------------------------------------------------------------
  // Chay mot lenh 2D + doi chieu trang thai ket thuc
  //---------------------------------------------------------------------------
  virtual task run_2d(int c = -1);
    int cc = (c < 0) ? int'(ch) : c;
    bit [31:0] st, xs, ys, sa, da;

    cfg_2d(cc);
    enable_ch(cc);

    if (expect_cfg_err) begin
      wait_cfg_err(cc);
      clear_ch_status(cc);
      return;
    end

    if (expect_idle) begin
      // Khong du kien transfer nao: poll mot khoang roi kiem tra khong co loi.
      // DONE co the len hoac khong tuy cach RTL ket thuc lenh rong -> chi LOG.
      repeat (20) apb_read(ch_addr(cc,O_STATUS), st);
      if (st[S_ERR]) begin
        bit [31:0] ei;
        apb_read(ch_addr(cc,O_ERRINFO), ei);
        `uvm_error(get_type_name(), $sformatf(
          "CH%0d khong du kien transfer nhung co STAT_ERR (STATUS=0x%08h ERRINFO=0x%08h)",
          cc, st, ei))
      end
      `uvm_info(get_type_name(), $sformatf(
        "CH%0d khong co transfer du kien; STATUS=0x%08h (DONE=%0b)",
        cc, st, st[S_DONE]), UVM_LOW)
    end
    else begin
      wait_ch_done(cc);
    end

    // Live counter cuoi lenh
    apb_read(ch_addr(cc,O_XSIZE),   xs);
    apb_read(ch_addr(cc,O_YSIZE),   ys);
    apb_read(ch_addr(cc,O_SRCADDR), sa);
    apb_read(ch_addr(cc,O_DESADDR), da);
    `uvm_info(get_type_name(), $sformatf(
      "CH%0d ket thuc: SRCXSIZE=%0d DESXSIZE=%0d SRCYSIZE=%0d DESYSIZE=%0d SRCADDR=0x%08h DESADDR=0x%08h",
      cc, xs[15:0], xs[31:16], ys[15:0], ys[31:16], sa, da), UVM_LOW)

    if (chk_src_drained && xs[15:0] !== 16'd0)
      `uvm_error(get_type_name(), $sformatf(
        "CH%0d mong doi SRCXSIZE=0 khi ket thuc, doc duoc %0d", cc, xs[15:0]))
    if (chk_des_drained && xs[31:16] !== 16'd0)
      `uvm_error(get_type_name(), $sformatf(
        "CH%0d mong doi DESXSIZE=0 khi ket thuc, doc duoc %0d", cc, xs[31:16]))

    clear_ch_status(cc);
  endtask

  //---------------------------------------------------------------------------
  // body mac dinh: POR + responder roi chay mot lenh 2D.
  //---------------------------------------------------------------------------
  virtual task body();
    super.body();
    run_2d();
  endtask

endclass : dma350_vseq_2d_base

`endif // DMA350_VSEQ_2D_BASE_SV
