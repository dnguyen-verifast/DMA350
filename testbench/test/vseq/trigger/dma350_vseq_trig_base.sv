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

    check_trig_ports();

    `uvm_info(get_type_name(), $sformatf(
      "CFG TRIG CH%0d: TYPE=%0b MODE=%0b SEL=%0d BLKSIZE=%0d (block=%0d) xsize=%0d",
      ch, trig_type, trig_mode, trig_sel, blksize, blksize+1, xsize), UVM_LOW)
  endtask

  //===========================================================================
  // DIEU PHOI CONG TRIGGER SRC / DES
  //---------------------------------------------------------------------------
  // Co N_TRIG_PORTS = 4 cong trigger vat ly (TI0..TI3), DUNG CHUNG cho ca hai
  // phia: SRC chon cong bang CH_SRCTRIGINCFG.SEL (knob trig_sel), DES chon cong
  // bang CH_DESTRIGINCFG.SEL (knob des_trig_sel khi separate_des_cfg = 1, nguoc
  // lai DES dung chung cau hinh -> chung cong voi SRC).
  //
  // Dung src_port()/des_port() thay vi doc thang trig_sel/des_trig_sel de logic
  // "des ke thua cau hinh src" chi nam o MOT cho.
  //===========================================================================
  localparam int N_TRIG_PORTS = 4;

  // Cong TI thuc te ma moi phia dang dung.
  // LUU Y: chi co y nghia "cong TI" khi TRIGTYPE = TT_HW. Voi TT_INTERNAL,
  // truong SEL la SO CHANNEL nguon (xem vseq internal), con TT_SW thi SEL bi
  // bo qua -> khong duoc dem hai gia tri nay di ban trigger ngoai.
  function int src_port();
    return int'(trig_sel);
  endfunction

  function int des_port();
    return separate_des_cfg ? int'(des_trig_sel) : int'(trig_sel);
  endfunction

  // TRIGTYPE thuc te cua phia DES (ke thua SRC khi khong tach cau hinh)
  function bit [1:0] des_type();
    return separate_des_cfg ? des_trig_type : trig_type;
  endfunction

  // TRIGMODE thuc te cua phia DES
  function bit [1:0] des_mode();
    return separate_des_cfg ? des_trig_mode : trig_mode;
  endfunction

  // Kiem tra cong hop le + co agent active lai chan
  function bit port_ok(int p, string who = "");
    if (p < 0 || p >= N_TRIG_PORTS) begin
      `uvm_error(get_type_name(), $sformatf(
        "%s: cong TI%0d vuot so cong trigger (%0d) - khong co agent nao lai chan nay",
        who, p, N_TRIG_PORTS))
      return 0;
    end
    if (p_sequencer.trig_seqr_h[p] == null) begin
      `uvm_error(get_type_name(), $sformatf(
        "%s: trig_seqr_h[%0d] = null (agent trigger passive?)", who, p))
      return 0;
    end
    return 1;
  endfunction

  //---------------------------------------------------------------------------
  // Kiem tra cap cong src/des truoc khi chay (goi trong cfg_trig_ch).
  // TRM 5.6.3: "The same trigger is selected for both source and destination
  // sides" la mot nguyen nhan TRIGGER SELECTION ERROR -> neu ca hai phia cung
  // bat va cung tro toi mot cong, DMAC se bao loi chu khong chay.
  //---------------------------------------------------------------------------
  function void check_trig_ports();
    if (!use_srctrig || !use_destrig) return;
    if (trig_type != TT_HW || des_type() != TT_HW) return;
    if (src_port() == des_port())
      `uvm_warning(get_type_name(), $sformatf(
        "CH%0d: SRC va DES cung chon cong TI%0d - TRM 5.6.3 coi day la trigger selection error. Dat separate_des_cfg=1 va des_trig_sel khac trig_sel neu muon dung ca hai phia.",
        ch, src_port()))
  endfunction

  //---------------------------------------------------------------------------
  // Trigger NGOAI (HW): ban n request kieu 'rt' tren mot cong TI.
  //---------------------------------------------------------------------------
  // start_item(item, priority, sequencer) cho phep vseq ban item toi SEQUENCER
  // CON ma khong can tao sequence rieng - dung cho ca 4 reqtype (cac seq co san
  // cua VIP moi cai chi co dinh 1 kieu).
  // port = -1 -> dung cong cua SOURCE (giu tuong thich voi cac vseq cu).
  // Nen dung send_src_trig/send_des_trig thay vi truyen so cong bang tay.
  virtual task send_hw_trig(bit [1:0] rt, int unsigned n = 1, int port = -1);
    dma_trig_reqtype_e rq = dma_trig_reqtype_e'(rt);
    int p = (port < 0) ? src_port() : port;
    if (!port_ok(p, "send_hw_trig")) return;
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

  //---------------------------------------------------------------------------
  // API theo PHIA - vseq con khong can biet so cong.
  //---------------------------------------------------------------------------
  virtual task send_src_trig(bit [1:0] rt, int unsigned n = 1);
    if (!use_srctrig)
      `uvm_warning(get_type_name(),
        "send_src_trig() nhung use_srctrig=0 - CH_CTRL.USESRCTRIGIN khong bat")
    if (trig_type != TT_HW)
      `uvm_warning(get_type_name(), $sformatf(
        "send_src_trig() nhung SRC TRIGTYPE=%0b (khong phai HW) - SEL=%0d khong phai cong TI. Dung send_sw_srctrig() cho SW, hoac internal trigger cho ch->ch.",
        trig_type, trig_sel))
    send_hw_trig(rt, n, src_port());
  endtask

  virtual task send_des_trig(bit [1:0] rt, int unsigned n = 1);
    if (!use_destrig)
      `uvm_warning(get_type_name(),
        "send_des_trig() nhung use_destrig=0 - CH_CTRL.USEDESTRIGIN khong bat")
    if (des_type() != TT_HW)
      `uvm_warning(get_type_name(), $sformatf(
        "send_des_trig() nhung DES TRIGTYPE=%0b (khong phai HW) - SEL=%0d khong phai cong TI. Dung send_sw_destrig() cho SW.",
        des_type(), des_port()))
    send_hw_trig(rt, n, des_port());
  endtask

  //---------------------------------------------------------------------------
  // BAN TRIGGER CHO CA HAI PHIA - dung cho moi test ket hop src/des.
  //
  // VI SAO PHAI SONG SONG:
  //   finish_item() chi tra ve SAU khi xong 4-phase handshake (req^ -> ack^ ->
  //   req v -> ack v). O COMMAND mode, TRM 5.4.1.1 noi DMAC cho CA HAI req roi
  //   moi ack -> neu ban tuan tu (src xong roi moi des) se TREO o req dau tien.
  //   Vi vay hai phia luon chay trong fork...join.
  //
  //   des_first : 1 = phat req DES truoc (dung nhu TRM Figure 5-15), 0 = SRC truoc
  //   skew      : khoang tre giua req thu nhat va req thu hai
  //               (0 = phat gan nhu dong thoi)
  //
  //   Giua hai req co goi hook during_pair_gap() - vseq con override de kiem tra
  //   trang thai channel trong luc MOI CO MOT req (vd: chua duoc phep chay).
  //---------------------------------------------------------------------------
  virtual task send_both_trig(bit [1:0]    src_rt,
                              bit [1:0]    des_rt,
                              int unsigned n_src    = 1,
                              int unsigned n_des    = 1,
                              bit          des_first = 1,
                              time         skew      = 0ns);
    `uvm_info(get_type_name(), $sformatf(
      "TRIG PAIR: %s truoc, skew=%0t | SRC TI%0d x%0d reqtype=%0b | DES TI%0d x%0d reqtype=%0b",
      des_first ? "DES" : "SRC", skew,
      src_port(), n_src, src_rt, des_port(), n_des, des_rt), UVM_LOW)

    fork
      begin : src_branch
        if (!des_first) send_src_trig(src_rt, n_src);
        else begin
          #(skew);
          send_src_trig(src_rt, n_src);
        end
      end
      begin : des_branch
        if (des_first) send_des_trig(des_rt, n_des);
        else begin
          #(skew);
          send_des_trig(des_rt, n_des);
        end
      end
      begin : gap_branch
        // Diem quan sat khi MOI CO req cua phia di truoc.
        if (skew > 0ns) #(skew / 2);
        during_pair_gap(des_first);
      end
    join
  endtask

  // Hook mac dinh rong. Override o vseq con neu can check giua hai req.
  virtual task during_pair_gap(bit des_first);
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
      use_srctrig ? "on" : "off", mode_name(trig_mode), src_port(), blksize+1,
      use_destrig ? "on" : "off",
      mode_name(des_mode()),
      des_port(),
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
