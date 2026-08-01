//==============================================================================
// dma350_vseq_2d_stream_base.sv
//------------------------------------------------------------------------------
// Base cho cac test KET HOP 2D + AXI4-STREAM (TRM 5.5, Table 5-6).
// Ke thua dma350_vseq_stream_base (lai str_in, hung str_out) va them 2D.
//
// TABLE 5-6 (Stream interface for 1D and 2D types) - to hop DUOC PHEP:
//   2D  XTYPE=Continue  YTYPE=Continue  -> Yes
//   2D  XTYPE=Continue  YTYPE=Fill      -> Yes
//   2D  XTYPE=Continue  YTYPE=Wrap      -> No  (config error)
//   2D  XTYPE=Wrap      bat ky YTYPE    -> No
//   2D  XTYPE=Fill      bat ky YTYPE    -> No
// -> vseq DUONG o day chi dung XTYPE=Continue + YTYPE=Continue/Fill.
//    Cac to hop bi cam nam trong nhom test AM (dma350_vseq_2d_neg_*_stream).
//==============================================================================
`ifndef DMA350_VSEQ_2D_STREAM_BASE_SV
`define DMA350_VSEQ_2D_STREAM_BASE_SV

class dma350_vseq_2d_stream_base extends dma350_vseq_stream_base;
  `uvm_object_utils(dma350_vseq_2d_stream_base)

  localparam bit [2:0] XT_CONT = 3'b001, XT_WRAP = 3'b010, XT_FILL = 3'b011;
  localparam bit [2:0] YT_DIS  = 3'b000, YT_CONT = 3'b001,
                       YT_WRAP = 3'b010, YT_FILL = 3'b011;

  localparam int EI_CFGERR = 1, EI_REGVALERR = 25, EI_CFGCONFLERR = 26;

  // ---- knob 2D ----
  int unsigned src_ysize   = 4;
  int unsigned des_ysize   = 4;
  int          src_ystride = 'h40;
  int          des_ystride = 'h40;
  bit [2:0]    ytype       = YT_CONT;
  bit [2:0]    xtype       = XT_CONT;
  bit [31:0]   fillval     = 32'hA5A5_5A5A;

  // du kien CONFIG ERROR (dung cho to hop bi cam trong Table 5-6)
  bit expect_cfg_err = 0;

  function new(string name = "dma350_vseq_2d_stream_base");
    super.new(name);
    src_addr = 32'h0008_0000;
    des_addr = 32'h0008_8000;
    src_n    = 8;                     // element / dong
    des_n    = 8;
    in_beats = 32;                    // 8 element x 4 dong
  endfunction

  //---------------------------------------------------------------------------
  // cfg stream cua stream_base + phu them 2D
  //---------------------------------------------------------------------------
  virtual task cfg_stream_ch();
    bit [31:0] c;
    super.cfg_stream_ch();

    apb_write(ch_addr(ch,O_YSIZE),       {des_ysize[15:0], src_ysize[15:0]});
    apb_write(ch_addr(ch,O_YADDRSTRIDE), {des_ystride[15:0], src_ystride[15:0]});
    apb_write(ch_addr(ch,O_FILLVAL),     fillval);

    // stream_base ghi CH_CTRL voi XTYPE=continue -> xoa [14:9] roi ghi lai
    apb_read(ch_addr(ch,O_CTRL), c);
    c = (c & ~32'h0000_7E00) | ({29'b0, ytype} << 12) | ({29'b0, xtype} << 9);
    apb_write(ch_addr(ch,O_CTRL), c);

    `uvm_info(get_type_name(), $sformatf(
      "CFG 2D+STREAM CH%0d: %0dx%0d -> %0dx%0d XTYPE=%03b YTYPE=%03b STREAMTYPE=%02b",
      ch, src_n, src_ysize, des_n, des_ysize, xtype, ytype, streamtype), UVM_LOW)
  endtask

  //---------------------------------------------------------------------------
  // Cho CONFIG ERROR (to hop bi cam)
  //---------------------------------------------------------------------------
  virtual task wait_cfg_err();
    bit [31:0] st, ei;
    repeat (poll_limit) begin
      apb_read(ch_addr(ch,O_STATUS), st);
      if (st[S_ERR]) begin
        apb_read(ch_addr(ch,O_ERRINFO), ei);
        if (!ei[EI_CFGERR])
          `uvm_error(get_type_name(), $sformatf(
            "CH%0d STAT_ERR nhung ERRINFO.CFGERR=0 (0x%08h)", ch, ei))
        else
          `uvm_info(get_type_name(), $sformatf(
            "CH%0d CONFIG ERROR dung mong doi (ERRINFO=0x%08h)", ch, ei), UVM_LOW)
        return;
      end
      if (st[S_DONE]) begin
        `uvm_error(get_type_name(), $sformatf(
          "CH%0d mong doi CONFIG ERROR nhung lenh chay xong (STATUS=0x%08h)", ch, st))
        return;
      end
    end
    `uvm_error(get_type_name(), $sformatf("CH%0d TIMEOUT cho CONFIG ERROR", ch))
  endtask

  //---------------------------------------------------------------------------
  // body: giong stream_base nhung co nhanh cho config error.
  // Goi thang dma350_vseq_base::body() de bo qua body() cua stream_base.
  //---------------------------------------------------------------------------
  virtual task body();
    dma350_vseq_base::body();          // por + responders
    cfg_stream_ch();
    enable_ch(ch);

    if (expect_cfg_err) begin
      wait_cfg_err();
      clear_ch_status(ch);
      return;
    end

    if (use_stream && drive_in)
      drive_stream_in(in_beats);
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_stream_base

`endif // DMA350_VSEQ_2D_STREAM_BASE_SV
