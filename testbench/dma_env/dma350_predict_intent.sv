    `ifndef dma350_predict_intent_INCLUDE_
    `define dma350_predict_intent_INCLUDE_
    // DMACH<n> register offset (byte offset trong 1 block channel)
    localparam bit [7:0]
        CH_CMD=8'h00, CH_STATUS=8'h04, CH_INTREN=8'h08, CH_CTRL=8'h0C,
        CH_SRCADDR=8'h10, CH_SRCADDRHI=8'h14, CH_DESADDR=8'h18, CH_DESADDRHI=8'h1C,
        CH_XSIZE=8'h20, CH_XSIZEHI=8'h24, CH_SRCTRANSCFG=8'h28, CH_DESTRANSCFG=8'h2C,
        CH_XADDRINC=8'h30, CH_YADDRSTRIDE=8'h34, CH_FILLVAL=8'h38, CH_YSIZE=8'h3C,
        CH_TMPLTCFG=8'h40, CH_SRCTMPLT=8'h44, CH_DESTMPLT=8'h48,
        CH_SRCTRIGINCFG=8'h4C, CH_DESTRIGINCFG=8'h50, CH_TRIGOUTCFG=8'h54,
        CH_GPOEN0=8'h58, CH_GPOVAL0=8'h60, CH_STREAMINTCFG=8'h68, CH_LINKATTR=8'h70,
        CH_AUTOCFG=8'h74, CH_LINKADDR=8'h78, CH_LINKADDRHI=8'h7C,
        CH_GPOREAD0=8'h80, CH_ERRINFO=8'h90;

    // CH_CMD bit
    localparam int CMD_ENABLECMD=0, CMD_CLEARCMD=1, CMD_DISABLECMD=2,
                   CMD_STOPCMD=3, CMD_PAUSECMD=4, CMD_RESUMECMD=5;
    // CH_STATUS bit
    localparam int ST_STAT_DONE=16, ST_STAT_ERR=17, ST_STAT_STOPPED=18,
                   ST_STAT_DISABLED=19, ST_STAT_PAUSED=20, ST_STAT_RESUMEWAIT=21,
                   ST_STAT_SRCTRIGWAIT=24, ST_STAT_DESTRIGWAIT=25, ST_STAT_TRIGOUTWAIT=26;
    // CH_INTREN bit
    localparam int IE_DONE=0, IE_ERR=1, IE_DISABLED=2, IE_STOPPED=3;
    // CH_ERRINFO type-flag bit
    localparam int EI_BUSERR=0, EI_CFGERR=1, EI_SRCTRIGSELERR=2, EI_DESTRIGSELERR=3,
                   EI_TRIGOUTSELERR=4, EI_STREAMERR=5,
                   EI_AXIRDRESPERR=16, EI_AXIWRRESPERR=17;

    // trigger ack encoding (TRM Table 5-5)
    localparam bit [1:0] TRIGACK_OKAY=2'b00, TRIGACK_DENY=2'b01, TRIGACK_LASTOKAY=2'b10;

    // AXI burst/resp
    localparam bit [1:0] BURST_FIXED=2'b00, BURST_INCR=2'b01;
    localparam bit [1:0] RESP_OKAY=2'b00, RESP_SLVERR=2'b10, RESP_DECERR=2'b11;

    localparam int MAX_BYTES_PER_BURST = 1024;   // DMA-350 burst payload cap
    localparam int MAX_CHANNELS        = 8;

//=============================================================================
// dma_golden_intent : snapshot cau hinh 1 command tai thoi diem ENABLECMD.
// Day la "y dinh" chot cung; predictor va ref-memory doc tu day.
//=============================================================================
class dma_golden_intent extends uvm_object;
    // ---- nhan dang / vong doi (dung boi cac checker nhan intent qua analysis) --
    int        ch_id;                     // channel nao
    bit        valid;                     // 1 = intent dang hieu luc (channel active)
                                          // 0 = channel vua ket thuc/disable
    bit        disablecmd;
    // Channel khoi dong bang TRIGGER NGOAI (HW) thay vi chi bang ENABLECMD.
    // => KHONG duoc phat AR du lieu truoc khi handshake trigger-in hoan tat.
    bit        ext_cmd;

    // dia chi + kich thuoc
    bit [63:0] srcaddr, desaddr;
    int        src_xsize, des_xsize;      // so item nguon/dich

    int        src_transize, des_transize; // log2 byte / item
    int signed src_xaddrinc, des_xaddrinc; // buoc dia chi (element)
    // kieu transfer
    int        xtype, ytype;              // CH_CTRL.XTYPE/YTYPE
    bit        wrap_en, fill_en;
    int        ysize, desysize, srcysize;                     // so dong 2D
    int signed src_stride, des_stride;    // buoc dong 2D (byte)
    bit [31:0] fillval;
    // burst limit
    int        src_maxburstlen, des_maxburstlen; // beats = value+1
    // dieu khien / autorestart / link
    bit cmdrstren;
    bit [15:0] cmdrestrcnt;
    int        chprio, donetype, regreloadtype;
    bit        usestream, donepauseen;
    bit [63:0] linkaddr; bit linkaddren;
    // thuoc tinh AXI (tu TRANSCFG)
    bit [2:0]  src_prot, des_prot;
    bit [3:0]  src_cache, des_cache, src_inner, des_inner;
    bit [1:0]  src_domain, des_domain;
    // trigger cfg
    bit        use_srctrig, use_destrig, use_trigout;
    int        srctrig_blksize, destrig_blksize;
    bit [1:0]  srctrig_type, destrig_type, trigout_type;
    // SEL = CONG trigger <TI>/<TO> ma channel nay dung (CH_*TRIGINCFG[7:0]).
    // Channel != cong trigger -> checker phai index trig_in_* bang SEL nay.
    bit [7:0]  srctrig_sel, destrig_sel, trigout_sel;
    // MODE = CH_*TRIGINCFG[11:10] (command / flow-control)
    bit [1:0]  srctrig_mode, destrig_mode;

    bit [1:0] streamtype;
    bit       usestream_out,usestream_in;

    bit       intren_done;

    `uvm_object_utils(dma_golden_intent)
    function new(string name="dma_golden_intent"); super.new(name); endfunction

    // tong so byte 1D (mot dong) va toan transfer (co 2D)
    function int line_bytes(); return src_xsize << src_transize; endfunction
    function int total_src_bytes();
        return line_bytes() * ((ytype!=0 && ysize>0) ? ysize : 1);
    endfunction
endclass


//=============================================================================
// dma350_predict_intent : PREDICTOR cau hinh lenh.
//-----------------------------------------------------------------------------
// Nhiem vu DUY NHAT: phat hien thoi diem mot channel ACTIVATE, chot toan bo
// config cua channel do thanh dma_golden_intent roi BROADCAST cho moi component
// quan tam (scoreboard, cmd_trigger_checker, coverage...).
//
// Tach khoi scoreboard vi:
//   * scoreboard chi nen lo viec DOI CHIEU, khong kiem luon viec dich config
//   * nhieu component can cung mot "y dinh" -> phat 1 lan, nhieu noi dung
//
// NGUON DU LIEU (deu la analysis, khong ai phai poll):
//   apb_imp : ghi thanh ghi qua APB  -> cap nhat reg_mirror (fallback khi chua
//             co backdoor)
//   sc_imp  : snapshot status per-cycle -> bat CANH LEN cua ch_enabled
//             (phu ca 3 duong khoi dong: APB ENABLECMD, command-link, autoboot)
//
// LAY CONFIG: uu tien BACKDOOR peek qua RAL (thay dung gia tri RTL dang dung,
// ke ca khi command-link/boot nap descriptor ma SW khong he ghi APB); neu chua
// co backdoor thi roi ve reg_mirror.
//
// DINH THOI: doi 1 clock sau canh len ch_enabled roi moi peek - command-link/
// boot can vai chu ky de nap descriptor vao thanh ghi.
//=============================================================================
`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_sc)

class dma350_predict_intent extends uvm_component;
    `uvm_component_utils(dma350_predict_intent)

    // ---- cong vao ----
    // apb_imp : GIU LAI. Day la nguon nuoi reg_mirror - duong FALLBACK duy nhat
    //           khi backdoor peek khong dung duoc (m_ral null / khong co HDL
    //           path). Bo no di thi peek_or_mirror() luon tra 0.
    // sc_imp  : BO. Viec phat hien "channel activate" da chuyen han sang FSM
    //           lenh trong cmd_trigger_checker (no goi emit_intent truc tiep),
    //           nen predictor khong con can theo doi canh len ch_enabled nua.
    uvm_analysis_imp_apb #(apb_seq_item_master, dma350_predict_intent) apb_imp;

    // ---- cong ra : intent cho scoreboard / checker ----
    // Van giu de emit_invalidate() (va bat ky ai muon dung predictor doc lap)
    // co duong phat. Duong CHINH hien nay la cmd_trigger_checker.intent_ap.
    uvm_analysis_port #(dma_golden_intent) intent_ap;

    // ---- phu thuoc ----
    ral_dma350           m_ral;      // backdoor peek (co the null -> dung mirror)
    virtual dma350_sc_if m_sc_vif;   // lay clock de settle truoc khi peek
    int                  num_channels = 1;

    // ---- trang thai noi bo ----
    bit [31:0] reg_mirror [int][bit [7:0]];   // [ch][offset]
    int        n_activations = 0;

    function new(string name = "dma350_predict_intent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        apb_imp   = new("apb_imp",   this);
        intent_ap = new("intent_ap", this);

        if (!uvm_config_db#(int)::get(this, "", "num_channels", num_channels))
            num_channels = 1;
        // Thu lay RAL qua config_db, NHUNG thuong that bai: build_phase cua cac
        // component anh em chay theo THU TU ALPHABET ten instance, ma
        // "predict_intent_h" < "reg_env_h" nen reg_env chua kip publish.
        // => dma350_env.connect_phase gan truc tiep predict_intent_h.m_ral.
        // Kiem tra lai o end_of_elaboration (sau khi connect da chay).
        void'(uvm_config_db#(ral_dma350)::get(this, "", "m_ral_model", m_ral));
        if (!uvm_config_db#(virtual dma350_sc_if)::get(this, "", "sc_vif", m_sc_vif))
            `uvm_info("PRED_CFG",
              "khong co sc_vif : peek se khong tri hoan 1 clock", UVM_MEDIUM)
    endfunction

    //-------------------------------------------------------------------------
    // RESET : xoa mirror. Sau reset thanh ghi ve gia tri reset cua RTL, giu lai
    // mirror cu se khien peek_or_mirror() tra gia tri CHET cua lenh truoc do.
    //-------------------------------------------------------------------------
    function void reset_mirror();
        reg_mirror.delete();
        `uvm_info("PRED_INT", "reset : xoa reg_mirror", UVM_HIGH)
    endfunction

    //-------------------------------------------------------------------------
    // (1) APB : chi CAP NHAT MIRROR. Khong chot intent o day - viec chot la do
    //     FSM lenh trong cmd_trigger_checker goi emit_intent() quyet dinh.
    //-------------------------------------------------------------------------
    virtual function void write_apb(apb_seq_item_master t);
        bit [12:0] a13;
        int        ch;
        bit [7:0]  off;
        if (t == null) return;                   // kiem TRUOC khi cham t.paddr
        if (!t.pwrite) return;
        a13 = t.paddr[12:0];
        if (!a13[12]) return;                    // khong phai vung DMACH
        ch  = int'(a13[10:8]);
        off = a13[7:0];
        if (ch >= num_channels) return;
        reg_mirror[ch][off] = t.pwdata;
    endfunction

    // //-------------------------------------------------------------------------
    // // (2) Status/Control : bat canh len/xuong cua ch_enabled.
    // //     write() la function nen KHONG the @clock o day -> day channel vao
    // //     hang doi, run_phase se xu ly (co the settle 1 clock roi peek).
    // //-------------------------------------------------------------------------
    // virtual function void write_sc(dma350_sc_item t);
    //     for (int ch = 0; ch < num_channels; ch++) begin
    //         bit en = t.ch_enabled[ch];
    //         if (en && !prev_enabled[ch]) begin
    //             pend_activate.push_back(ch);            // canh LEN -> chot intent
    //         end
    //         else if (!en && prev_enabled[ch]) begin
    //             emit_invalidate(ch);                    // canh XUONG -> het hieu luc
    //         end
    //         prev_enabled[ch] = en;
    //     end
    // endfunction

    //-------------------------------------------------------------------------
    // run_phase : xu ly hang doi activation (can doi clock nen phai o task)
    //-------------------------------------------------------------------------
    // task run_phase(uvm_phase phase);
    //     forever begin
    //         wait (pend_activate.size() > 0);
    //         begin
    //             int ch = pend_activate.pop_front();
    //             settle_one_clock();
    //             emit_intent(ch);
    //         end
    //     end
    // endtask

    // task settle_one_clock();
    //     if (m_sc_vif != null) @(posedge m_sc_vif.clk);
    //     else                  #0;
    // endtask

    //-------------------------------------------------------------------------
    // Bao cho downstream biet intent cua channel het hieu luc
    //-------------------------------------------------------------------------
    function void emit_invalidate(int ch);
        dma_golden_intent gi = dma_golden_intent::type_id::create("gi_inv");
        gi.ch_id = ch;
        gi.valid = 0;
        intent_ap.write(gi);
        `uvm_info("PRED_INT", $sformatf("CH%0d intent het hieu luc", ch), UVM_HIGH)
    endfunction

    //-------------------------------------------------------------------------
    // Chot config -> dma_golden_intent -> broadcast
    //-------------------------------------------------------------------------
    task emit_intent(input int ch, output dma_golden_intent chanel_intent);
        dma_golden_intent gi;
        bit [31:0] ctrl, xsz, xszhi, xinc, ystr, sctc, dstc, scfg, dcfg, tocfg;
        bit [31:0] sa_lo, sa_hi, da_lo, da_hi, fillv, ysz, la_lo, la_hi;
        bit [31:0] streamcfg, intren, autorestart, cmd;

        chanel_intent = null;
        // Chan index sai TRUOC khi cham vao m_ral.dmach[ch] : ral_reg() co kiem
        // bien nhung neu m_ral null thi khong, va reg_mirror[ch] se tao entry rac.
        if (ch < 0 || ch >= num_channels) begin
            `uvm_error("PRED_INT", $sformatf(
              "emit_intent: ch=%0d ngoai dai [0..%0d] - bo qua", ch, num_channels-1))
            return;
        end

        gi = dma_golden_intent::type_id::create("gi");
        peek_or_mirror(ch, CH_CMD,          cmd);
        peek_or_mirror(ch, CH_CTRL,         ctrl);
        peek_or_mirror(ch, CH_XSIZE,        xsz);
        peek_or_mirror(ch, CH_XSIZEHI,      xszhi);
        peek_or_mirror(ch, CH_XADDRINC,     xinc);
        peek_or_mirror(ch, CH_YADDRSTRIDE,  ystr);
        peek_or_mirror(ch, CH_SRCTRANSCFG,  sctc);
        peek_or_mirror(ch, CH_DESTRANSCFG,  dstc);
        peek_or_mirror(ch, CH_SRCTRIGINCFG, scfg);
        peek_or_mirror(ch, CH_DESTRIGINCFG, dcfg);
        peek_or_mirror(ch, CH_TRIGOUTCFG,   tocfg);
        peek_or_mirror(ch, CH_SRCADDR,      sa_lo);
        peek_or_mirror(ch, CH_SRCADDRHI,    sa_hi);
        peek_or_mirror(ch, CH_DESADDR,      da_lo);
        peek_or_mirror(ch, CH_DESADDRHI,    da_hi);
        peek_or_mirror(ch, CH_FILLVAL,      fillv);
        peek_or_mirror(ch, CH_YSIZE,        ysz);
        peek_or_mirror(ch, CH_LINKADDR,     la_lo);
        peek_or_mirror(ch, CH_LINKADDRHI,   la_hi);
        peek_or_mirror(ch, CH_STREAMINTCFG,   streamcfg);
        peek_or_mirror(ch, CH_INTREN,   intren);
        peek_or_mirror(ch, CH_AUTOCFG,   autorestart);
        gi.ch_id        = ch;
        gi.valid        = 1;
        gi.disablecmd   = cmd[2];

        gi.srcaddr      = {sa_hi, sa_lo};
        gi.desaddr      = {da_hi, da_lo};
        gi.src_xsize    = {xszhi[15:0],  xsz[15:0]};
        gi.des_xsize    = {xszhi[31:16], xsz[31:16]};
        gi.src_transize = ctrl[2:0];
        gi.des_transize = ctrl[2:0];
        gi.chprio       = ctrl[7:4];
        gi.xtype        = ctrl[11:9];
        gi.ytype        = ctrl[14:12];
        gi.wrap_en      = (ctrl[11:9] == 3'b010);
        gi.fill_en      = (ctrl[11:9] == 3'b011);
        gi.regreloadtype= ctrl[20:18];
        gi.donetype     = ctrl[23:21];
        gi.donepauseen  = ctrl[24];
        gi.usestream    = ctrl[29];
        gi.src_xaddrinc = $signed(xinc[15:0]);
        gi.des_xaddrinc = $signed(xinc[31:16]);
        gi.src_stride   = $signed(ystr[15:0]);
        gi.des_stride   = $signed(ystr[31:16]);
        gi.fillval      = fillv;
        // CH_YSIZE : SRCYSIZE = [15:0], DESYSIZE = [31:16]. ysize (dung chung cho
        // total_src_bytes) lay theo phia NGUON.
        gi.srcysize     = int'(ysz[15:0]);
        gi.desysize     = int'(ysz[31:16]);
        gi.ysize        = gi.srcysize;

        gi.src_maxburstlen = sctc[19:16];
        gi.des_maxburstlen = dstc[19:16];
        gi.src_cache  = sctc[7:4]; gi.src_inner = sctc[3:0]; gi.src_domain = sctc[9:8];
        gi.src_prot   = {1'b0, sctc[10], sctc[11]};
        gi.des_cache  = dstc[7:4]; gi.des_inner = dstc[3:0]; gi.des_domain = dstc[9:8];
        gi.des_prot   = {1'b0, dstc[10], dstc[11]};

        // ---- trigger cfg (CH_CTRL cho ENABLE, CH_*TRIGINCFG cho SEL/TYPE/MODE)
        gi.use_srctrig  = ctrl[25];
        gi.use_destrig  = ctrl[26];
        gi.use_trigout  = ctrl[27];
        gi.srctrig_sel  = scfg[7:0];    gi.srctrig_type = scfg[9:8];
        gi.srctrig_mode = scfg[11:10];  gi.srctrig_blksize = scfg[23:16];
        gi.destrig_sel  = dcfg[7:0];    gi.destrig_type = dcfg[9:8];
        gi.destrig_mode = dcfg[11:10];  gi.destrig_blksize = dcfg[23:16];
        gi.trigout_sel  = tocfg[7:0];   gi.trigout_type = tocfg[9:8];


        // ext_cmd : channel cho TRIGGER NGOAI (HW) truoc khi chay.
        // TYPE = 2'b10 = HW (00=SW, 11=internal) -> chi HW moi co handshake tren
        // chan trig_in_*; SW/internal khong co, khong ap check flow duoc.
        gi.ext_cmd = ctrl[25] && (scfg[9:8] == 2'b10);
        gi.cmdrstren   = autorestart[16];
        gi.cmdrestrcnt = autorestart[15:0];
        // CH_LINKADDR : bit0 = LINKADDREN, dia chi descriptor la [63:2]<<2 (word
        // aligned) - bit0/1 KHONG thuoc dia chi nen phai mask di, khong thi
        // linkaddr lech 1 byte so voi AR ma DUT phat.
        gi.linkaddr   = {la_hi, la_lo} & ~64'h3;
        gi.linkaddren = la_lo[0];

        // ---- STREAM : CH_STREAMINTCFG[10:9] = STREAMTYPE ----
        //   00 = ca hai chieu, 01 = stream OUT (des), 10 = stream IN (src)
        // Cac truong nay la CUA gi (dma_golden_intent), truoc day bi ghi thieu
        // tien to "gi." nen tro thanh bien khong khai bao -> loi compile.
        gi.streamtype    = streamcfg[10:9];
        gi.usestream_out = gi.usestream && (gi.streamtype == 2'b01 || gi.streamtype == 2'b00);
        gi.usestream_in  = gi.usestream && (gi.streamtype == 2'b10 || gi.streamtype == 2'b00);
        gi.intren_done   = intren[IE_DONE];
        n_activations++;
        `uvm_info("PRED_INT", $sformatf(
          "CH%0d ACTIVATE -> intent: src=0x%0h des=0x%0h SRCXSIZE=%0d DESXSIZE=%0d xtype=%0b ext_cmd=%0b srctrig_sel=%0d",
          ch, gi.srcaddr, gi.desaddr, gi.src_xsize, gi.des_xsize,
          gi.xtype, gi.ext_cmd, gi.srctrig_sel), UVM_MEDIUM)

        // KHONG write() o day: nguoi goi (cmd_trigger_checker FSM) moi biet
        // intent nay ung voi giai doan nao cua lenh va tu phat qua intent_ap
        // cua no. Phat ca hai noi se lam scoreboard chot intent 2 lan.
        chanel_intent = gi;
    endtask

    //-------------------------------------------------------------------------
    // BACKDOOR peek helper (giong scoreboard): uu tien RAL, fallback mirror
    //-------------------------------------------------------------------------
    function uvm_reg ral_reg(int ch, bit [7:0] off);
        if (m_ral == null)                     return null;
        if (ch < 0 || ch >= m_ral.dmach.size()) return null;
        case (off)
            // 4 thanh ghi duoi day TRUOC DAY BI THIEU o day: emit_intent co peek
            // chung nhung ral_reg() tra null -> roi ve reg_mirror; ma cac test
            // dung command-link / autoboot khong he ghi chung qua APB nen mirror
            // rong -> cmd/intren/autocfg/streamintcfg LUON doc ra 0. Hau qua:
            // intren_done=0, cmdrstren=0, usestream_out=0 -> FSM lenh chon nham
            // dieu kien ket thuc va treo o ST_ENABLE.
            CH_CMD:          return m_ral.dmach[ch].ch_cmd;
            CH_INTREN:       return m_ral.dmach[ch].ch_intren;
            CH_AUTOCFG:      return m_ral.dmach[ch].ch_autocfg;
            CH_STREAMINTCFG: return m_ral.dmach[ch].ch_streamintcfg;
            CH_STATUS:       return m_ral.dmach[ch].ch_status;
            CH_LINKATTR:     return m_ral.dmach[ch].ch_linkattr;
            CH_CTRL:         return m_ral.dmach[ch].ch_ctrl;
            CH_SRCADDR:      return m_ral.dmach[ch].ch_srcaddr;
            CH_SRCADDRHI:    return m_ral.dmach[ch].ch_srcaddrhi;
            CH_DESADDR:      return m_ral.dmach[ch].ch_desaddr;
            CH_DESADDRHI:    return m_ral.dmach[ch].ch_desaddrhi;
            CH_XSIZE:        return m_ral.dmach[ch].ch_xsize;
            CH_XSIZEHI:      return m_ral.dmach[ch].ch_xsizehi;
            CH_SRCTRANSCFG:  return m_ral.dmach[ch].ch_srctranscfg;
            CH_DESTRANSCFG:  return m_ral.dmach[ch].ch_destranscfg;
            CH_XADDRINC:     return m_ral.dmach[ch].ch_xaddrinc;
            CH_YADDRSTRIDE:  return m_ral.dmach[ch].ch_yaddrstride;
            CH_FILLVAL:      return m_ral.dmach[ch].ch_fillval;
            CH_YSIZE:        return m_ral.dmach[ch].ch_ysize;
            CH_SRCTRIGINCFG: return m_ral.dmach[ch].ch_srctrigincfg;
            CH_DESTRIGINCFG: return m_ral.dmach[ch].ch_destrigincfg;
            CH_TRIGOUTCFG:   return m_ral.dmach[ch].ch_trigoutcfg;
            CH_LINKADDR:     return m_ral.dmach[ch].ch_linkaddr;
            CH_LINKADDRHI:   return m_ral.dmach[ch].ch_linkaddrhi;
            default:         return null;
        endcase
    endfunction

    task peek_or_mirror(int ch, bit [7:0] off, output bit [31:0] val);
        uvm_reg        r = ral_reg(ch, off);
        uvm_status_e   st;
        uvm_reg_data_t d;
        val = 0;
        if (r != null && (r.get_backdoor() != null || r.has_hdl_path())) begin
            r.peek(st, d);
            if (st == UVM_IS_OK) begin
                `uvm_info("PEEK_REG", "st == UVM_IS_OK : intent chot bang BACKDOOR peek", UVM_LOW) 
                val = d[31:0]; return; end
        end
        // fallback: mirror tu APB write
        if (reg_mirror.exists(ch) && reg_mirror[ch].exists(off))
            `uvm_info("PEEK_REG", "Mirror_apb: intent chot bang FRONTDOOR peek", UVM_LOW)
            val = reg_mirror[ch][off];
    endtask

    //-------------------------------------------------------------------------
    // Chay SAU connect_phase: luc nay m_ral phai da co. Neu van null thi moi
    // peek se roi ve reg_mirror va cac thanh ghi test KHONG ghi qua APB (vd
    // CH_SRCTRANSCFG/CH_DESTRANSCFG, von co gia tri reset 0x000F0400) se doc ra
    // 0 -> maxburstlen=0 -> burst du doan sai. Bao ERROR thay vi de im lang.
    //-------------------------------------------------------------------------
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        if (m_ral == null)
            `uvm_error("PRED_CFG",
              "m_ral = null : intent se lay tu reg_mirror, cac thanh ghi khong duoc SW ghi (CH_*TRANSCFG...) se doc ra 0 thay vi gia tri reset. Gan predict_intent_h.m_ral trong env.connect_phase.")
        else
            `uvm_info("PRED_CFG", "RAL san sang : intent chot bang BACKDOOR peek", UVM_LOW)
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("PRED_INT", $sformatf("tong so lan chot intent (activation): %0d",
                  n_activations), UVM_LOW)
    endfunction

endclass

`endif