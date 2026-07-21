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
    int        ysize;                     // so dong 2D
    int signed src_stride, des_stride;    // buoc dong 2D (byte)
    bit [31:0] fillval;
    // burst limit
    int        src_maxburstlen, des_maxburstlen; // beats = value+1
    // dieu khien / autorestart / link
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
    uvm_analysis_imp_apb #(apb_seq_item_master, dma350_predict_intent) apb_imp;
    uvm_analysis_imp_sc  #(dma350_sc_item,      dma350_predict_intent) sc_imp;

    // ---- cong ra : intent cho scoreboard / checker ----
    uvm_analysis_port #(dma_golden_intent) intent_ap;

    // ---- phu thuoc ----
    ral_dma350           m_ral;      // backdoor peek (co the null -> dung mirror)
    virtual dma350_sc_if m_sc_vif;   // lay clock de settle truoc khi peek
    int                  num_channels = 1;

    // ---- trang thai noi bo ----
    bit [31:0] reg_mirror [int][bit [7:0]];   // [ch][offset]
    bit        prev_enabled [int];            // phat hien canh len ch_enabled
    int        n_activations = 0;

    // hang doi channel cho activate (write() la function, khong the doi clock)
    int        pend_activate [$];

    function new(string name = "dma350_predict_intent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        apb_imp   = new("apb_imp",   this);
        sc_imp    = new("sc_imp",    this);
        intent_ap = new("intent_ap", this);

        if (!uvm_config_db#(int)::get(this, "", "num_channels", num_channels))
            num_channels = 1;
        void'(uvm_config_db#(ral_dma350)::get(this, "", "m_ral_model", m_ral));
        if (!uvm_config_db#(virtual dma350_sc_if)::get(this, "", "sc_vif", m_sc_vif))
            `uvm_info("PRED_CFG",
              "khong co sc_vif : peek se khong tri hoan 1 clock", UVM_MEDIUM)

        for (int c = 0; c < num_channels; c++) prev_enabled[c] = 0;
    endfunction

    //-------------------------------------------------------------------------
    // (1) APB : chi CAP NHAT MIRROR. Khong chot intent o day - viec chot do
    //     canh len ch_enabled quyet dinh (xem write_sc).
    //-------------------------------------------------------------------------
    virtual function void write_apb(apb_seq_item_master t);
        bit [12:0] a13 = t.paddr[12:0];
        int        ch;
        bit [7:0]  off;
        if (!a13[12]) return;                 // khong phai vung DMACH
        ch  = int'(a13[10:8]);
        off = a13[7:0];
        if (ch >= num_channels) return;
        if (t.pwrite) reg_mirror[ch][off] = t.pwdata;
    endfunction

    //-------------------------------------------------------------------------
    // (2) Status/Control : bat canh len/xuong cua ch_enabled.
    //     write() la function nen KHONG the @clock o day -> day channel vao
    //     hang doi, run_phase se xu ly (co the settle 1 clock roi peek).
    //-------------------------------------------------------------------------
    virtual function void write_sc(dma350_sc_item t);
        for (int ch = 0; ch < num_channels; ch++) begin
            bit en = t.ch_enabled[ch];
            if (en && !prev_enabled[ch]) begin
                pend_activate.push_back(ch);            // canh LEN -> chot intent
            end
            else if (!en && prev_enabled[ch]) begin
                emit_invalidate(ch);                    // canh XUONG -> het hieu luc
            end
            prev_enabled[ch] = en;
        end
    endfunction

    //-------------------------------------------------------------------------
    // run_phase : xu ly hang doi activation (can doi clock nen phai o task)
    //-------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        forever begin
            wait (pend_activate.size() > 0);
            begin
                int ch = pend_activate.pop_front();
                settle_one_clock();
                emit_intent(ch);
            end
        end
    endtask

    task settle_one_clock();
        if (m_sc_vif != null) @(posedge m_sc_vif.clk);
        else                  #0;
    endtask

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
    task emit_intent(int ch);
        dma_golden_intent gi = dma_golden_intent::type_id::create("gi");
        bit [31:0] ctrl, xsz, xszhi, xinc, ystr, sctc, dstc, scfg, dcfg, tocfg;
        bit [31:0] sa_lo, sa_hi, da_lo, da_hi, fillv, ysz, la_lo, la_hi;

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

        gi.ch_id        = ch;
        gi.valid        = 1;

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
        gi.ysize        = ysz & 32'h0000_FFFF;

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

        gi.linkaddr   = {la_hi, la_lo};
        gi.linkaddren = la_lo[0];

        n_activations++;
        `uvm_info("PRED_INT", $sformatf(
          "CH%0d ACTIVATE -> intent: src=0x%0h des=0x%0h SRCXSIZE=%0d DESXSIZE=%0d xtype=%0b ext_cmd=%0b srctrig_sel=%0d",
          ch, gi.srcaddr, gi.desaddr, gi.src_xsize, gi.des_xsize,
          gi.xtype, gi.ext_cmd, gi.srctrig_sel), UVM_MEDIUM)

        intent_ap.write(gi);
    endtask

    //-------------------------------------------------------------------------
    // BACKDOOR peek helper (giong scoreboard): uu tien RAL, fallback mirror
    //-------------------------------------------------------------------------
    function uvm_reg ral_reg(int ch, bit [7:0] off);
        if (m_ral == null)                     return null;
        if (ch < 0 || ch >= m_ral.dmach.size()) return null;
        case (off)
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
            if (st == UVM_IS_OK) begin val = d[31:0]; return; end
        end
        // fallback: mirror tu APB write
        if (reg_mirror.exists(ch) && reg_mirror[ch].exists(off))
            val = reg_mirror[ch][off];
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("PRED_INT", $sformatf("tong so lan chot intent (activation): %0d",
                  n_activations), UVM_LOW)
    endfunction

endclass

`endif