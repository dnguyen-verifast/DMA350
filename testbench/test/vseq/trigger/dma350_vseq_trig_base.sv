//==============================================================================
// dma350_vseq_trig_base.sv
//------------------------------------------------------------------------------
// Base cho bo test DMAC operation triggers (TRM 5.4 "Trigger interface").
// Cac vseq con chi set knob trong new() roi goi run_trig().
//
// MA HOA THANH GHI (lay tu RTL dma350_pkg.sv / dma350_ch_regs.sv - KHONG doan):
//
//   CH_CTRL      [25] USESRCTRIGIN   [26] USEDESTRIGIN   [27] USETRIGOUT
//   CH_*TRIGINCFG  SEL=[7:0]  TYPE=[9:8]  MODE=[11:10]  BLKSIZE=[23:16]
//   CH_TRIGOUTCFG  SEL=[7:0]  TYPE=[9:8]
//
//   TRIGTYPE : 2'b00 SW        2'b10 HW (cong ngoai)   2'b11 INTERNAL (ch->ch)
//   TRIGMODE : 2'b00 CMD       2'b10 FLOW_DMA          2'b11 FLOW_PERI
//              (RTL: flowctrl = trigin_en & trigin_mode[1] -> bit1=1 la flow ctl;
//               TYPE=INTERNAL bi RTL ep ve TRIGMODE_CMD bat ke MODE ghi gi)
//
//   CH_CMD   [16] SRCSWTRIGINREQ  [18:17] SRCSWTRIGINTYPE
//            [20] DESSWTRIGINREQ  [22:21] DESSWTRIGINTYPE
//            [24] SWTRIGOUTACK
//
//   TRIGREQ (req_type/SWTRIGINTYPE) : 00 SINGLE  01 LAST_SINGLE
//                                     10 BLOCK   11 LAST_BLOCK
//
// LUONG CHUAN cua mot test trigger ngoai (HW):
//   1. cfg_trig_ch()  : cau hinh channel + bat USESRCTRIGIN, chon cong TI
//   2. enable_ch()    : channel vao trang thai cho trigger (KHONG tu chay)
//   3. ban sequence trigger tren p_sequencer.trig_seqr_h[<cong TI>]
//   4. wait_ch_done() : chi xong khi da nhan du trigger
//
// cmd_trigger_checker chay nen se bat loi "AR du lieu truoc handshake trigger".
//==============================================================================
`ifndef DMA350_VSEQ_TRIG_BASE_SV
`define DMA350_VSEQ_TRIG_BASE_SV

class dma350_vseq_trig_base extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_trig_base)

  // ---- TRIGTYPE (CH_*TRIGINCFG[9:8]) ----
  localparam bit [1:0] TT_SW       = 2'b00,
                       TT_HW       = 2'b10,
                       TT_INTERNAL = 2'b11;
  // ---- TRIGMODE (CH_*TRIGINCFG[11:10]) ----
  localparam bit [1:0] TM_CMD       = 2'b00,
                       TM_FLOW_DMA  = 2'b10,
                       TM_FLOW_PERI = 2'b11;
  // ---- TRIGREQ (req_type) ----
  localparam bit [1:0] RQ_SINGLE      = 2'b00,
                       RQ_LAST_SINGLE = 2'b01,
                       RQ_BLOCK       = 2'b10,
                       RQ_LAST_BLOCK  = 2'b11;
  // ---- bit CH_CMD cho software trigger ----
  localparam int B_SRCSWTRIGREQ = 16, B_SRCSWTRIGTYPE = 17,
                 B_DESSWTRIGREQ = 20, B_DESSWTRIGTYPE = 21,
                 B_SWTRIGOUTACK = 24;

  // ---- knob cau hinh channel ----
  int unsigned ch          = 0;
  bit [31:0]   src_addr    = 32'h0000_1000;
  bit [31:0]   des_addr    = 32'h0000_2000;
  int unsigned xsize       = 16;
  bit [2:0]    transize    = 3'd2;              // word (4B)

  // ---- knob trigger : phia SOURCE (CH_SRCTRIGINCFG) ----
  bit          use_srctrig = 1;
  bit [1:0]    trig_type   = TT_HW;             // SW / HW / INTERNAL
  bit [1:0]    trig_mode   = TM_CMD;            // CMD / FLOW_DMA / FLOW_PERI
  bit [7:0]    trig_sel    = 8'd0;              // cong TI (0..3) hoac channel nguon
  bit [7:0]    blksize     = 8'd3;              // block = BLKSIZE + 1 (4 item)

  // ---- knob trigger : phia DESTINATION (CH_DESTRIGINCFG) ----
  // Mac dinh separate_des_cfg=0 -> DES dung CHUNG cau hinh voi SRC (giu tuong
  // thich cho cac vseq chi dung 1 phia). Dat =1 khi SRC va DES can MODE/cong
  // KHAC nhau (vd TRM Fig 5-17: src=flow-control, des=command).
  bit          use_destrig      = 0;
  bit          separate_des_cfg = 0;
  bit [1:0]    des_trig_type = TT_HW;
  bit [1:0]    des_trig_mode = TM_CMD;
  bit [7:0]    des_trig_sel  = 8'd1;            // cong TI khac voi source
  bit [7:0]    des_blksize   = 8'd3;

  // ---- knob trigger-out ----
  bit          use_trigout = 0;
  bit [7:0]    trigout_sel = 8'd0;
  bit [1:0]    trigout_type= TT_HW;

  function new(string name = "dma350_vseq_trig_base");
    super.new(name);
  endfunction

  //---------------------------------------------------------------------------
  // Cau hinh 1 channel + phan trigger
  //---------------------------------------------------------------------------
  virtual task cfg_trig_ch();
    bit [31:0] ctrl;
    bit [31:0] trigincfg;

    // ---- phan transfer (1D continue) ----
    apb_write(ch_addr(ch,O_SRCADDR),   src_addr);
    apb_write(ch_addr(ch,O_SRCADDRHI), 32'h0);
    apb_write(ch_addr(ch,O_DESADDR),   des_addr);
    apb_write(ch_addr(ch,O_DESADDRHI), 32'h0);
    apb_write(ch_addr(ch,O_XSIZE),     {xsize[15:0], xsize[15:0]});
    apb_write(ch_addr(ch,O_XADDRINC),  32'h0001_0001);
    apb_write(ch_addr(ch,O_YSIZE),     32'h0);

    // ---- CH_SRCTRIGINCFG : SEL | TYPE | MODE | BLKSIZE ----
    trigincfg = {8'h0, blksize,                       // [23:16] BLKSIZE
                 4'h0, trig_mode, trig_type,          // [11:10] MODE, [9:8] TYPE
                 trig_sel};                           // [7:0]   SEL
    if (use_srctrig) apb_write(ch_addr(ch,O_SRCTRIGINCFG), trigincfg);

    // ---- CH_DESTRIGINCFG : rieng neu separate_des_cfg, khong thi giong SRC ----
    if (use_destrig) begin
      bit [31:0] descfg;
      descfg = separate_des_cfg
             ? {8'h0, des_blksize, 4'h0, des_trig_mode, des_trig_type, des_trig_sel}
             : trigincfg;
      apb_write(ch_addr(ch,O_DESTRIGINCFG), descfg);
    end
    if (use_trigout)
      apb_write(ch_addr(ch,O_TRIGOUTCFG),
                {16'h0, 4'h0, 2'b00, trigout_type, trigout_sel});

    // ---- CH_CTRL : DONETYPE=end-of-cmd | XTYPE=continue | USE*TRIG | TRANSIZE
    ctrl = (32'h1 << 21) | (32'h1 << 9) | {29'b0, transize};
    if (use_srctrig) ctrl |= (32'h1 << 25);
    if (use_destrig) ctrl |= (32'h1 << 26);
    if (use_trigout) ctrl |= (32'h1 << 27);
    apb_write(ch_addr(ch,O_CTRL),   ctrl);
    apb_write(ch_addr(ch,O_INTREN), 32'h3);       // IE_DONE | IE_ERR

    `uvm_info(get_type_name(), $sformatf(
      "CFG TRIG CH%0d: TYPE=%0b MODE=%0b SEL=%0d BLKSIZE=%0d (block=%0d) xsize=%0d",
      ch, trig_type, trig_mode, trig_sel, blksize, blksize+1, xsize), UVM_LOW)
  endtask

  //---------------------------------------------------------------------------
  // Trigger NGOAI (HW): ban n request kieu 'rt' tren cong trig_sel.
  // Cong TI phai < so agent trigger (4) - neu khong khong co ai lai chan.
  //---------------------------------------------------------------------------
  // start_item(item, priority, sequencer) cho phep vseq ban item toi SEQUENCER
  // CON ma khong can tao sequence rieng - dung cho ca 4 reqtype (cac seq co san
  // cua VIP moi cai chi co dinh 1 kieu).
  // port = -1 -> dung trig_sel (cong cua SOURCE). Test ket hop truyen cong
  // rieng cho phia destination (vd src dung TI0, des dung TI1).
  virtual task send_hw_trig(bit [1:0] rt, int unsigned n = 1, int port = -1);
    dma_trig_reqtype_e rq = dma_trig_reqtype_e'(rt);
    int p = (port < 0) ? int'(trig_sel) : port;
    if (p >= 4) begin
      `uvm_error(get_type_name(), $sformatf(
        "cong TI%0d vuot so cong trigger (4) - khong co agent nao lai chan nay", p))
      return;
    end
    if (p_sequencer.trig_seqr_h[p] == null) begin
      `uvm_error(get_type_name(), $sformatf(
        "trig_seqr_h[%0d] = null (agent trigger passive?)", p))
      return;
    end
    for (int i = 0; i < n; i++) begin
      dma_trig_item it = dma_trig_item::type_id::create("trig_it");
      start_item(it, -1, p_sequencer.trig_seqr_h[p]);
      if (!it.randomize() with { reqtype  == rq;
                                 pre_delay inside {[0:3]};
                                 err_reqtype_change == 0; })
        `uvm_error(get_type_name(), "randomize trig item that bai")
      finish_item(it);
      `uvm_info(get_type_name(), $sformatf(
        "gui trigger TI%0d reqtype=%s -> acktype=%s",
        p, it.reqtype.name(), it.observed_acktype.name()), UVM_MEDIUM)
    end
  endtask

  // Ten mode cho log/ban ghi - de doc log biet ngay src/des dang o mode nao
  function string mode_name(bit [1:0] m);
    case (m)
      TM_CMD:       return "COMMAND";
      TM_FLOW_DMA:  return "FLOW_CONTROL(DMA)";
      TM_FLOW_PERI: return "FLOW_CONTROL(PERI)";
      default:      return "RESERVED";
    endcase
  endfunction

  // In ro cau hinh HAI PHIA (dung cho cac test ket hop src/des khac mode)
  function void log_src_des_mode();
    `uvm_info(get_type_name(), $sformatf(
      "CH%0d TRIGGER: SRC[%s]=%s cong TI%0d blk=%0d | DES[%s]=%s cong TI%0d blk=%0d",
      ch,
      use_srctrig ? "on" : "off", mode_name(trig_mode), trig_sel, blksize+1,
      use_destrig ? "on" : "off",
      mode_name(separate_des_cfg ? des_trig_mode : trig_mode),
      separate_des_cfg ? des_trig_sel : trig_sel,
      (separate_des_cfg ? des_blksize : blksize) + 1), UVM_LOW)
  endfunction

  //---------------------------------------------------------------------------
  // Software trigger qua CH_CMD (khong dung chan ngoai).
  //   SRCSWTRIGINREQ/TYPE : bit16 / [18:17]
  //   DESSWTRIGINREQ/TYPE : bit20 / [22:21]
  //---------------------------------------------------------------------------
  virtual task send_sw_srctrig(bit [1:0] rt);
    apb_write(ch_addr(ch,O_CMD),
              (32'h1 << B_SRCSWTRIGREQ) | ({30'b0, rt} << B_SRCSWTRIGTYPE));
    `uvm_info(get_type_name(), $sformatf(
      "SW src-trigger CH%0d reqtype=%0b", ch, rt), UVM_MEDIUM)
  endtask

  virtual task send_sw_destrig(bit [1:0] rt);
    apb_write(ch_addr(ch,O_CMD),
              (32'h1 << B_DESSWTRIGREQ) | ({30'b0, rt} << B_DESSWTRIGTYPE));
    `uvm_info(get_type_name(), $sformatf(
      "SW des-trigger CH%0d reqtype=%0b", ch, rt), UVM_MEDIUM)
  endtask

  // SW acknowledge cho trigger-out (thay cho chan trig_out_ack)
  virtual task send_sw_trigout_ack();
    apb_write(ch_addr(ch,O_CMD), 32'h1 << B_SWTRIGOUTACK);
    `uvm_info(get_type_name(), $sformatf("SW trigout-ack CH%0d", ch), UVM_MEDIUM)
  endtask

  //---------------------------------------------------------------------------
  // Kiem tra channel DANG CHO trigger: da enable nhung chua DONE.
  // Doc CH_STATUS va soi bit SRCTRIGINWAIT (24) / DESTRIGINWAIT (25).
  //---------------------------------------------------------------------------
  virtual task check_waiting_trigger(string what = "SRCTRIGINWAIT");
    bit [31:0] st;
    apb_read(ch_addr(ch,O_STATUS), st);
    `uvm_info(get_type_name(), $sformatf(
      "CH%0d STATUS=0x%08h (DONE=%0b SRCTRIGWAIT=%0b DESTRIGWAIT=%0b) - %s",
      ch, st, st[16], st[24], st[25], what), UVM_LOW)
    if (st[16])
      `uvm_error(get_type_name(), $sformatf(
        "CH%0d da DONE truoc khi nhan trigger -> channel khong cho trigger", ch))
  endtask

  //---------------------------------------------------------------------------
  // body mac dinh cua vseq con: POR + responder (tu dma350_vseq_base)
  //---------------------------------------------------------------------------
  virtual task body();
    super.body();
  endtask

endclass : dma350_vseq_trig_base

`endif // DMA350_VSEQ_TRIG_BASE_SV
