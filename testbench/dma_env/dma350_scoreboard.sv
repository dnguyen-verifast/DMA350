`ifndef dma350_scoreboard_INCLUDE_
`define dma350_scoreboard_INCLUDE_
//=============================================================================
// dma350_scoreboard.sv  -  CoreLink DMA-350 UVM scoreboard
//
// Chien luoc (theo ghi chu chien luoc cua verification plan):
//
//   register-side  = "y dinh / golden" (SW lap trinh gi)
//   interface-side = "thuc te"          (bus lam gi)
//
// Scoreboard doi chieu CA HAI CHIEU:
//   * predict tu register  -> so voi giao dich interface (AR/AW/W/trig/gpo)
//   * suy nguoc tu interface -> so voi status/counter trong register (readback)
//
// Vi read-side va write-side cua DMA-350 lech pha qua FIFO noi bo, ta KHONG
// so truc tiep read<->write theo thoi gian. Thay vao do:
//
//        PREDICTOR  ->  REFERENCE-MEMORY (byte @ address)  ->  COMPARATOR
//
//   - PREDICTOR   : phan ra golden-intent thanh chuoi burst AR/AW ky vong
//   - REF-MEMORY  : hung data tren R-channel, ap bien doi lenh (copy/fill/2D...)
//                   -> tinh byte ghi ky vong tai dung dia chi dich
//   - COMPARATOR  : so byte W thuc te voi ref-memory theo WSTRB, tai dung addr
//
// Moi channel (toi 8) co context rieng: golden intent, FSM, outstanding, counter.
//
// Ghi chu tich hop: file nay gia dinh package cha da import:
//     uvm_pkg, axi5_globals_pkg (enum AXI), dma350 sc pkg (`DMA350_SC_*),
//     va cac class item (axi5_slave_tx, apb_seq_item_master, axis_seq_item,
//     boot_seq_item, dma_trig_item, crlp_seq_item, dma350_sc_item) + ral_dma350.
//=============================================================================

//-----------------------------------------------------------------------------
// Cac hang so cuc bo (mirror tu dma350_pkg / TRM) - de khong phu thuoc bien
// dich RTL package trong moi truong verification.
//
// LUU Y: khong boc trong `package` de file co the `include vao 1 package UVM
// lon (package long nhau la bat hop le). Cac khai bao duoi day tro thanh thanh
// vien cua package/scope bao ngoai, duoc guard boi dma350_scoreboard_INCLUDE_.
//-----------------------------------------------------------------------------
// PHAN CHIA FILE:
//   dma350_predict_intent.sv  (include TRUOC file nay trong dma350_env_pkg.sv)
//     - localparam offset thanh ghi / bit STATUS / enum trang thai
//     - class dma_golden_intent   (y dinh lenh - do predictor chot va phat di)
//     - component dma350_predict_intent
//   file nay:
//     - class dma_axi_burst / dma_ch_ctx / dma_ref_memory  (trang thai noi bo
//       cua scoreboard, de ngay day cho de kiem soat)
//     - class dma350_scoreboard
// Dinh nghia lai bat ky thu gi cua file kia o day se gay "duplicate definition".
//-----------------------------------------------------------------------------

//=============================================================================
// dma_axi_burst : mot mo ta burst AXI ky vong (predictor sinh ra)
//=============================================================================
    typedef enum { CH_ST_DISABLED, CH_ST_ENABLED, CH_ST_PAUSED,
                   CH_ST_DONE, CH_ST_STOPPED, CH_ST_ERROR } ch_state_e;
    typedef enum {
        SW_CONTROL_MODE, TRIGGER_CONTROL_MODE, INTERNAL_TRIGGER_MODE 
    } dma_operation_mode_e;

    typedef enum {
       NOTHING_OCCUR , READ_ONLY, WRITE_ONLY, WRITE_READ
    } axi_operation_e;

//-----------------------------------------------------------------------------
// dma_axi_burst : BAN GHI DU DOAN THUOC TINH AXI CHO CA MOT COMMAND.
//
// KHONG con du doan "burst thu k dai bao nhieu beat, dia chi nao". Voi moi
// command scoreboard chi chot DUNG MOT ban ghi cho moi phia:
//     ctx.exp_rd    - MOI AR du lieu cua lenh phai thoa ban ghi nay
//     ctx.exp_wr    - MOI AW cua lenh phai thoa ban ghi nay
//     ctx.exp_link  - AR command-link fetch (doc descriptor) KE TIEP
//
// MUC TIEU kiem tra chi gom 3 nhom - KHONG di doan cach RTL toi uu giao dich:
//   (a) TOAN VEN DU LIEU : byte doc -> byte ghi dung dia chi (qua ref-memory)
//   (b) THUOC TINH TRUY CAP BO NHO : AxCACHE / AxPROT / AxDOMAIN / AxID / CHID
//   (c) HINH HOC CHE DO LENH : 1D continue / 2D / wrap / fill - AxADDR phai nam
//       trong cua so cua che do do va tong byte chuyen phai dung
//
// Kiem tra la kiem RANG BUOC, khong so bang tuyet doi:
//   * AxADDR nam trong cua so [addr_lo, addr_hi] cua lenh (INCR) hoac == addr
//     khi FIXED
//   * AxBURST / AxCACHE / AxPROT / AxDOMAIN / AxID / CHID dung cau hinh
//   * AxLEN+1 <= MAXBURSTLEN+1 ; so BYTE cua burst <= FIFO/2 ; khong vat qua
//     breakpoint 1KB ; <= 256 beat (INCR) / 16 beat (FIXED)
//
// CO Y KHONG KIEM: AxSIZE (beat size).
//   RTL duoc phep TOI UU beat size (gop len ca do rong bus khi template tat,
//   addrinc == 1, dia chi aligned...) va cach gop con phu thuoc FIFO / trigger /
//   arbitration. Doan xem no co toi uu hay khong chi sinh bao dong GIA ma khong
//   them gia tri: toan ven du lieu da duoc kiem truc tiep tren ref-memory bang
//   AxSIZE THUC TE cua giao dich. O day chi giu luat AXI: AxSIZE khong duoc
//   lon hon do rong bus. Cung ly do do, gioi han do dai burst duoc kiem theo
//   BYTE (FIFO/2, 1KB) chu khong theo so beat suy ra tu beat size da doan.
//
// Ban ghi nay con duoc dung lam ban ghi QUAN SAT (out_rd/out_wr) de ghep
// AR->R / AW->W: khi do chi cac truong addr/beats/size/fixed/is_cmdlink co y
// nghia.
//-----------------------------------------------------------------------------
class dma_axi_burst extends uvm_object;
    bit        valid;          // 1 = da co du doan cho phia nay
    bit        is_cmdlink;     // 1 = ban ghi cho command-link / autoboot fetch
    bit        is_boot;        // 1 = fetch descriptor dau tien do autoboot
    bit        is_read;

    // ---- pham vi dia chi & khoi luong CUA CA LENH ----
    bit [63:0] addr;           // dia chi bat dau
    longint    addr_lo, addr_hi;   // cua so dia chi hop le cho moi AxADDR
    longint    total_bytes;    // tong byte phia nay chuyen trong ca lenh

    // ---- beat size : chi de THAM KHAO / log, KHONG dung de so sanh ----------
    // = TRANSIZE cua lenh clamp theo do rong bus. RTL co the dung beat lon hon
    // (toi uu) - do la hop le, nen khong doi chieu truong nay.
    int        size;

    // ---- gioi han do dai burst ---------------------------------------------
    int        max_beats;      // gioi han so BEAT: min(MAXBURSTLEN+1, 256|16)
    int        maxburst_beats; // MAXBURSTLEN + 1
    longint    fifo_max_bytes; // FIFO/2 : gioi han so BYTE cua mot burst

    // ---- kieu burst & thuoc tinh AXI ----
    bit        fixed;          // 1 = FIXED (XADDRINC == 0), 0 = INCR
    bit     [1:0]          burst;   // gia tri AxBURST ky vong
    bit     [3:0]          cache;   // MEMATTRHI -> AxCACHE
    bit     [3:0]          inner;   // MEMATTRLO -> inner cache attr
    bit     [2:0]          prot;    // {instruction, non-secure, privileged}
    bit     [3:0]          qos;     // CHPRIO -> AxQOS
    bit     [3:0]          region;
    bit                    wakeup;  // Pending AXI5 activity indicator
    bit     [1:0]          domain;  // SHAREATTR -> AxDOMAIN
    bit  [CHID_WIDTH-1:0]  chid;    // SW configurable channel ID indication
    bit     [7:0]          id;      // AxID = so channel

    // ---- ban ghi QUAN SAT (out_rd/out_wr) : mo ta burst THUC TE tren bus ----
    int        beats;

    // ---- thong ke da thay tren bus cho phia nay ----
    longint    seen_bytes;
    int        seen_bursts;

    `uvm_object_utils(dma_axi_burst)
    function new(string name="dma_axi_burst"); super.new(name); endfunction

    function int  len();        return beats-1;      endfunction   // AxLEN
    function int  beat_bytes(); return (1 << size);  endfunction
    function longint end_addr();return addr_lo + total_bytes; endfunction

    function string convert2string();
        return $sformatf(
          "%s addr=0x%0h win=[0x%0h,0x%0h) bytes=%0d maxbeats=%0d(MAXBURSTLEN+1=%0d) fifo/2=%0dB %s cache=0x%0h inner=0x%0h prot=0b%03b domain=%0b id=%0d chid=%0d (beatsize lenh=%0dB, khong doi chieu)",
          is_cmdlink ? (is_boot ? "BOOT-LINK" : "CMD-LINK") : (is_read ? "RD" : "WR"),
          addr, addr_lo, addr_hi, total_bytes,
          max_beats, maxburst_beats, fifo_max_bytes,
          fixed ? "FIXED" : "INCR",
          cache, inner, prot, domain, id, chid, (1<<size));
    endfunction
endclass

//=============================================================================
// dma_ch_ctx : context per-channel. Giu golden intent hien hanh, FSM, hang doi
// outstanding, con tro tien do va thong ke.
//=============================================================================
class dma_ch_ctx extends uvm_object;
    int              chan_id;
    ch_state_e       state = CH_ST_DISABLED;
    dma_operation_mode_e mode_operation = SW_CONTROL_MODE;
    dma_golden_intent intent;             // command dang chay (null neu idle)

    // predictor: MOT ban ghi thuoc tinh cho moi phia (khong con hang doi burst)
    dma_axi_burst    exp_rd;              // rang buoc cho moi AR du lieu
    dma_axi_burst    exp_wr;              // rang buoc cho moi AW
    dma_axi_burst    exp_link;            // rang buoc cho AR command-link ke tiep
    bit              link_armed;          // dang cho mot lan fetch descriptor

    // outstanding: pairing AR->R va AW->W de dat byte vao/ra ref-memory.
    // Day KHONG phai du doan - la ban ghi giao dich THUC TE dang bay.
    dma_axi_burst    out_rd[$];           // AR da phat, cho R data
    dma_axi_burst    out_wr[$];           // AW da phat, cho W data

    // stream byte nguon (theo thu tu doc) -> nap vao ref-memory dich
    bit [7:0]        src_stream[$];
    longint          des_fill_ptr;         // con tro byte dich ke tiep can nap ky vong

    //---- anh xa byte NGUON -> dia chi DICH ky vong ---------------------------
    // Thay cho dest_base/dest_cap gan vao tung burst du doan (khong con nua):
    // mot con tro chay theo dong/pass. Byte thu k doc duoc do vao des_ptr roi
    // tien len; het dong thi nhay sang dong ke tiep theo DES stride.
    bit              des_fixed;            // DESXADDRINC == 0 -> so sanh qua FIFO
    // Stream mode (CH_CTRL.USESTREAM): du lieu di vong qua AXI4-Stream (DMA doc
    // nguon tren AXI -> str_out; str_in -> DMA ghi dich tren AXI). Van co AR/AW
    // that tren AXI-M (RTL nay khong phan biet STREAMTYPE), nen VAN du doan dia
    // chi/so luong AR/AW; nhung NOI DUNG byte di qua stream nen BO so sanh
    // du lieu R->W qua ref-memory (tranh mismatch gia).
    bit              stream_mode;
    longint          des_ptr;              // dia chi dich cho byte nguon ke tiep
    longint          des_left;             // byte con nhan duoc cua dong dich
    longint          src_left;             // byte nguon con lai cua dong hien tai
    longint          des_line_base;        // dia chi goc cua dong dich hien tai
    longint          des_line_bytes;       // so byte dich moi dong
    longint          src_line_bytes;       // so byte nguon moi dong
    longint          des_line_stride;      // buoc dia chi giua 2 dong dich
    int              line_idx, line_count; // dong hien tai / tong so dong

    // bookkeeping
    longint          bytes_read  = 0;
    longint          bytes_written = 0;
    longint          exp_total_bytes = 0;
    int              outstanding_rd = 0, outstanding_wr = 0;

    // mirror thanh ghi (associative theo offset) - "y dinh SW" (frontdoor write)
    bit [31:0]       reg_mirror[bit [7:0]];
    // snapshot RAW config peek luc activation - dung cho RO-lock check khi enabled
    bit [31:0]       cfg_snapshot[bit [7:0]];

    // trang thai quan sat tu status/control bus
    bit              obs_enabled, obs_err, obs_stopped, obs_paused;
    bit              obs_priv, obs_nonsec; // ch_priv / ch_nonsec -> AxPROT[1:0]
    bit              prev_enabled;         // activation-detector (rising edge ch_enabled)

    // peek counter gan nhat (kiem tra don dieu + bounds tai bien bus-event)
    bit              cnt_peek_valid;
    longint          last_src_peek, last_des_peek;
    int              last_xsize_peek;

    // co loi da inject / quan sat
    bit              seen_rd_resp_err, seen_wr_resp_err;

    `uvm_object_utils(dma_ch_ctx)
    function new(string name="dma_ch_ctx"); super.new(name); endfunction

    // Xoa command hien tai. exp_link/link_armed KHONG bi xoa: mot lenh co
    // command-link da du doan truoc lan fetch descriptor ke tiep, ma lan fetch
    // do xay ra SAU khi lenh nay ket thuc.
    function void clear_command();
        intent = null;
        exp_rd = null; exp_wr = null;
        out_rd.delete(); out_wr.delete();
        src_stream.delete();
        des_fill_ptr = 0;
        bytes_read = 0; bytes_written = 0; exp_total_bytes = 0;
        des_ptr = 0; des_left = 0; src_left = 0;
        des_line_base = 0; des_line_bytes = 0; src_line_bytes = 0;
        des_line_stride = 0; line_idx = 0; line_count = 0;
        des_fixed = 0; stream_mode = 0;
    endfunction
endclass


//=============================================================================
// dma_ref_memory : reference-memory trung gian (byte @ address).
// exp[addr]=byte du kien ghi ; act[addr]=byte thuc te ghi.
//=============================================================================
class dma_ref_memory extends uvm_object;
    // associate array using for incr burst
    bit [7:0] exp   [longint];
    bit       exp_v [longint];
    bit [7:0] act   [longint];
    bit       act_v [longint];

    // queue array using for fixed, stream

    bit [7:0] exp_fifo [$];
    bit [7:0] act_fifo [$];

    int       mismatches = 0;
    int       match    = 0;

    `uvm_object_utils(dma_ref_memory)
    function new(string name="dma_ref_memory"); super.new(name); endfunction

    // predictor/ref-model dat byte du kien tai dia chi dich
    function void set_expected(longint a, bit [7:0] d);
        `uvm_info("DMA_REF_MM",$sformatf("set expected value for read / fillvalue"),UVM_LOW)
        exp[a] = d; exp_v[a] = 1;
        try_compare(a);
    endfunction

    // comparator: byte thuc te tu W-channel (chi khi wstrb=1)
    function void set_actual(longint a, bit [7:0] d);
        `uvm_info("DMA_REF_MM",$sformatf("set actual value for write"),UVM_LOW)
        act[a] = d; act_v[a] = 1;
        try_compare(a);
    endfunction

    // so khop theo NOI DUNG tai dia chi (khong theo thu tu thoi gian)
    function void try_compare(longint a);
        if (exp_v[a] && act_v[a]) begin
            if (exp[a] === act[a]) begin
                match++;
                `uvm_info("SB_DATA",
                    $sformatf("DATA MATCH @0x%0h : exp=0x%02h act=0x%02h",
                              a, exp[a], act[a]),UVM_LOW)
            end
            else begin
                mismatches++;
                `uvm_error("SB_DATA",
                    $sformatf("DATA MISMATCH @0x%0h : exp=0x%02h act=0x%02h",
                              a, exp[a], act[a]))
            end
            // da doi chieu: xoa de end-of-test chi con byte chua khop
            exp_v[a]=0; act_v[a]=0;
        end
    endfunction

    // comparing burst fixed with desaddincr = 0
    function void fixed_compare ( int beat, int destranszie);
        bit [7:0] expv_fifo, actv_fifo;
        for (int i= 0; i< beat; i++) begin
            for (int b=0; b< destranszie; b++) begin
                expv_fifo = exp_fifo.pop_front();
                actv_fifo = act_fifo.pop_front();
                if(expv_fifo == actv_fifo) begin
                    `uvm_info("SB_DATA",
                    $sformatf("DATA MATCH : exp=0x%02h act=0x%02h", expv_fifo, actv_fifo),UVM_LOW)
                end else `uvm_error("SB_DATA",
                    $sformatf("DATA MISMATCH : exp=0x%02h act=0x%02h", expv_fifo, actv_fifo))
            end
        end
    endfunction

    // end-of-test: liet ke byte du kien chua duoc ghi / ghi thua
    function void report_dangling(uvm_component c);
        int nexp=0, nact=0;
        foreach (exp_v[a]) if (exp_v[a]) nexp++;
        foreach (act_v[a]) if (act_v[a]) nact++;
        if (nexp) `uvm_error("SB_EOT",
            $sformatf("%0d byte du kien ghi nhung KHONG thay tren W-channel", nexp))
        if (nact) `uvm_error("SB_EOT",
            $sformatf("%0d byte ghi tren W-channel nhung KHONG duoc du doan", nact))
    endfunction
endclass


//=============================================================================
// Scoreboard chinh
//=============================================================================
class dma350_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(dma350_scoreboard)

    //---- handle & analysis FIFO (giu nguyen khai bao ban dau) ----------------
    axi5_slave_tx axi5_slave0_tx_h1, axi5_slave0_tx_h2, axi5_slave0_tx_h3,
                  axi5_slave0_tx_h4, axi5_slave0_tx_h5;
    axi5_slave_tx axi5_slave1_tx_h1, axi5_slave1_tx_h2, axi5_slave1_tx_h3,
                  axi5_slave1_tx_h4, axi5_slave1_tx_h5;

    uvm_tlm_analysis_fifo#(axi5_slave_tx) axi5_slave0_read_address_analysis_fifo;
    uvm_tlm_analysis_fifo#(axi5_slave_tx) axi5_slave0_read_data_analysis_fifo;
    uvm_tlm_analysis_fifo#(axi5_slave_tx) axi5_slave0_write_address_analysis_fifo;
    uvm_tlm_analysis_fifo#(axi5_slave_tx) axi5_slave0_write_data_analysis_fifo;
    uvm_tlm_analysis_fifo#(axi5_slave_tx) axi5_slave0_write_response_analysis_fifo;
    uvm_tlm_analysis_fifo#(axi5_slave_tx) axi5_slave1_read_address_analysis_fifo;
    uvm_tlm_analysis_fifo#(axi5_slave_tx) axi5_slave1_read_data_analysis_fifo;
    uvm_tlm_analysis_fifo#(axi5_slave_tx) axi5_slave1_write_address_analysis_fifo;
    uvm_tlm_analysis_fifo#(axi5_slave_tx) axi5_slave1_write_data_analysis_fifo;
    uvm_tlm_analysis_fifo#(axi5_slave_tx) axi5_slave1_write_response_analysis_fifo;

    axis_seq_item axis_slave_tx_h0, axis_master_tx_h0;
    uvm_tlm_analysis_fifo#(axis_seq_item) axis_slave_analysis_fifo_h0;
    uvm_tlm_analysis_fifo#(axis_seq_item) axis_master_analysis_fifo_h0;

    apb_seq_item_master apb_master_tx_h0;
    uvm_tlm_analysis_fifo#(apb_seq_item_master) apb_master_analysis_fifo_h0;

    boot_seq_item boot_tx_h0;
    uvm_tlm_analysis_fifo#(boot_seq_item) boot_analysis_fifo_h0;
    // setup port and item for trigger port 
    dma_trig_item dma_trig_tx_h0;
    // dma_trig_item dma_trig_tx_h1;
    // dma_trig_item dma_trig_tx_h2;
    // dma_trig_item dma_trig_tx_h3;
    uvm_tlm_analysis_fifo#(dma_trig_item) dma_trig_analysis_fifo_h0;
    // uvm_tlm_analysis_fifo#(dma_trig_item) dma_trig_analysis_fifo_h1;
    // uvm_tlm_analysis_fifo#(dma_trig_item) dma_trig_analysis_fifo_h2;
    // uvm_tlm_analysis_fifo#(dma_trig_item) dma_trig_analysis_fifo_h3;

    crlp_seq_item crlp_tx_h0;
    uvm_tlm_analysis_fifo#(crlp_seq_item) crlp_analysis_fifo_h0;

    dma350_sc_item dma350_sc_tx_h0;
    uvm_tlm_analysis_fifo#(dma350_sc_item) dma350_sta_ctrl_analysis_fifo_h0;

    //ral model dma (truy cap BACKDOOR - peek moi luc, khong can bus)
    ral_dma350 m_ral_dma_model;

    // virtual interface status/control : lay clock cho ky luat "1 clock sau
    // activation" truoc khi peek (config command-link/boot on dinh sau 1 clk).
    virtual dma350_sc_if m_sc_vif;
    bit                  m_backdoor_ok = 0;   // set neu HDL path hop le luc build

    //---- trang thai noi bo scoreboard ---------------------------------------
    dma_ch_ctx     ctx[MAX_CHANNELS];         // context per-channel
    dma_ref_memory refmem;                    // reference-memory dung chung
    int            num_channels = 1;          // lay tu config (mac dinh 1)

    // ---- tham so build cua DUT can cho viec du doan thuoc tinh AXI ----------
    // FIFO_DEPTH (so WORD bus) cua dma350_channel : FIFO/2 gioi han so byte mot
    // burst duoc mang. Lay qua config_db de khop voi tham so RTL cua test.
    int            fifo_depth_words = 16;
    // So beat toi da cua mot lan fetch descriptor command-link:
    // 1 header + 32 word thanh ghi (RTL doc suy doan het co, phan thua bi bo).
    int            cmdlink_max_beats = 16;

    // ---- autoboot : boot_en=1 thi lan doc command-link DAU TIEN cua Ch0 la
    //      fetch descriptor tai boot_addr voi boot_memattr/boot_shareattr ------
    bit            boot_en_seen = 0;
    longint        boot_fetch_addr = 0;
    bit [7:0]      boot_memattr = 0;
    bit [1:0]      boot_shareattr = 0;

    axi_operation_e axi_operation = WRITE_READ;

    //---- INTENT tu dma350_predict_intent ------------------------------------
    // Predictor chot config luc channel activate roi broadcast xuong day. Nho
    // vay scoreboard KHONG con phai tu peek/dich config nua - no chi lo doi
    // chieu. Dung analysis_fifo (khong phai imp) de xu ly trong run_phase,
    // vi build_predicted_bursts() can chay tuan tu voi cac luong khac.
    uvm_tlm_analysis_fifo #(dma_golden_intent) intent_analysis_fifo_h0;
    dma_golden_intent                          intent_tx_h0;

    // thong ke tong
    int  err_addr_mismatch = 0;
    int  err_status_mismatch = 0;
    int  err_trigger = 0;
    int  err_lpi = 0;
    int  n_commands = 0;

    //=========================================================================
    // constructor
    //=========================================================================
    function new (string name="dma350_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        axi5_slave0_write_address_analysis_fifo  = new("axi5_slave0_write_address_analysis_fifo",this);
        axi5_slave0_write_data_analysis_fifo     = new("axi5_slave0_write_data_analysis_fifo",this);
        axi5_slave0_write_response_analysis_fifo = new("axi5_slave0_write_response_analysis_fifo",this);
        axi5_slave0_read_address_analysis_fifo   = new("axi5_slave0_read_address_analysis_fifo",this);
        axi5_slave0_read_data_analysis_fifo      = new("axi5_slave0_read_data_analysis_fifo",this);
        axi5_slave1_write_address_analysis_fifo  = new("axi5_slave1_write_address_analysis_fifo",this);
        axi5_slave1_write_data_analysis_fifo     = new("axi5_slave1_write_data_analysis_fifo",this);
        axi5_slave1_write_response_analysis_fifo = new("axi5_slave1_write_response_analysis_fifo",this);
        axi5_slave1_read_address_analysis_fifo   = new("axi5_slave1_read_address_analysis_fifo",this);
        axi5_slave1_read_data_analysis_fifo      = new("axi5_slave1_read_data_analysis_fifo",this);
        axis_slave_analysis_fifo_h0  = new("axis_slave_analysis_fifo_h0",this);
        axis_master_analysis_fifo_h0 = new("axis_master_analysis_fifo_h0",this);
        apb_master_analysis_fifo_h0  = new("apb_master_analysis_fifo_h0",this);
        boot_analysis_fifo_h0        = new("boot_analysis_fifo_h0",this);

        intent_analysis_fifo_h0      = new("intent_analysis_fifo_h0",this);
        dma_trig_analysis_fifo_h0    = new("dma_trig_analysis_fifo_h0",this);
        // dma_trig_analysis_fifo_h1    = new("dma_trig_analysis_fifo_h1",this);
        // dma_trig_analysis_fifo_h2    = new("dma_trig_analysis_fifo_h2",this);
        // dma_trig_analysis_fifo_h3    = new("dma_trig_analysis_fifo_h3",this);

        crlp_analysis_fifo_h0        = new("crlp_analysis_fifo_h0",this);
        dma350_sta_ctrl_analysis_fifo_h0 = new("dma350_sta_ctrl_analysis_fifo_h0",this);
    endfunction

    //=========================================================================
    // build_phase : lay RAL + config; khoi tao context & ref-memory
    //=========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(int)::get(this, "", "num_channels", num_channels))
            num_channels = 1;
        // FIFO_DEPTH cua RTL (word bus). Mac dinh 16 nhu dma350_channel.
        if (!uvm_config_db#(int)::get(this, "", "fifo_depth_words", fifo_depth_words))
            fifo_depth_words = 16;
        void'(uvm_config_db#(ral_dma350)::get(this, "", "ral_dma_model", m_ral_dma_model));
        // vif status/control : nguon clock cho ky luat dinh thoi truoc peek
        if (!uvm_config_db#(virtual dma350_sc_if)::get(this, "", "sc_vif", m_sc_vif))
            `uvm_info("SB_CFG",
              "khong co sc_vif : peek se khong tri hoan 1 clock (dung #0)", UVM_MEDIUM)
        refmem = dma_ref_memory::type_id::create("refmem");
        foreach (ctx[i]) begin
            ctx[i] = dma_ch_ctx::type_id::create($sformatf("ctx%0d", i));
            ctx[i].chan_id = i;
        end
    endfunction

    //-------------------------------------------------------------------------
    // end_of_elaboration_phase : kiem tra HDL path cua RAL (BACKDOOR chi hoat
    // dong khi RAL da add_hdl_path tro dung instance register RTL). Neu path
    // sai/thieu, peek tra gia tri vo nghia MA KHONG bao loi -> phai canh bao.
    // Dung EOE thay vi connect_phase: m_ral_dma_model duoc gan trong
    // connect_phase cua ENV (cha) - chay SAU connect_phase cua scoreboard
    // (bottom-up), nen kiem tra o connect se luon thay null.
    //-------------------------------------------------------------------------
    function void end_of_elaboration_phase(uvm_phase phase);
        int nmiss = 0;
        bit [7:0] chk[$] = '{CH_CMD, CH_STATUS, CH_CTRL, CH_SRCADDR, CH_DESADDR,
                             CH_XSIZE, CH_ERRINFO};
        super.end_of_elaboration_phase(phase);
        if (m_ral_dma_model == null) begin
            `uvm_warning("SB_BD", "RAL model null : chi dung frontdoor mirror")
            return;
        end
        foreach (chk[i]) begin
            uvm_reg r = ral_reg(0, chk[i]);
            if (r == null || !r.has_hdl_path()) nmiss++;
        end
        if (nmiss > 0)
            `uvm_warning("SB_BD", $sformatf("%0d/%0d thanh ghi mau THIEU HDL path : backdoor peek se fallback ve frontdoor mirror. Hay add_hdl_path()/configure(.hdl_path()) cho RAL va kiem slicing field.", nmiss, chk.size()))
        else begin
            m_backdoor_ok = 1;
            `uvm_info("SB_BD", "HDL path RAL hop le : dung BACKDOOR peek", UVM_LOW)
        end
    endfunction

    //=========================================================================
    // run_phase : fork cac luong tieu thu doc lap. Predictor / ref-memory /
    // comparator chay dong thoi, dong bo qua noi dung ref-memory chu KHONG
    // qua thu tu thoi gian.
    //=========================================================================
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        fork
            // (0) INTENT tu dma350_predict_intent : chot config luc activate
            forever begin intent_analysis_fifo_h0.get(intent_tx_h0);
                          process_intent(intent_tx_h0); end
            // (1) APB : register write = golden intent ; register read = reconcile
            forever begin apb_master_analysis_fifo_h0.get(apb_master_tx_h0);
                          process_apb(apb_master_tx_h0); end
            // (3)(4) predictor + (5) data-integrity, M0
            forever begin axi5_slave0_read_address_analysis_fifo.get(axi5_slave0_tx_h1);
                          process_ar(axi5_slave0_tx_h1, 0); end
            forever begin axi5_slave0_read_data_analysis_fifo.get(axi5_slave0_tx_h2);
                          process_r (axi5_slave0_tx_h2, 0); end
            forever begin axi5_slave0_write_address_analysis_fifo.get(axi5_slave0_tx_h3);
                          process_aw(axi5_slave0_tx_h3, 0); end
            forever begin axi5_slave0_write_data_analysis_fifo.get(axi5_slave0_tx_h4);
                          process_w (axi5_slave0_tx_h4, 0); end
            forever begin axi5_slave0_write_response_analysis_fifo.get(axi5_slave0_tx_h5);
                          process_b (axi5_slave0_tx_h5, 0); end
            // M1 (neu present)
            forever begin axi5_slave1_read_address_analysis_fifo.get(axi5_slave1_tx_h1);
                          process_ar(axi5_slave1_tx_h1, 1); end
            forever begin axi5_slave1_read_data_analysis_fifo.get(axi5_slave1_tx_h2);
                          process_r (axi5_slave1_tx_h2, 1); end
            forever begin axi5_slave1_write_address_analysis_fifo.get(axi5_slave1_tx_h3);
                          process_aw(axi5_slave1_tx_h3, 1); end
            forever begin axi5_slave1_write_data_analysis_fifo.get(axi5_slave1_tx_h4);
                          process_w (axi5_slave1_tx_h4, 1); end
            forever begin axi5_slave1_write_response_analysis_fifo.get(axi5_slave1_tx_h5);
                          process_b (axi5_slave1_tx_h5, 1); end
            // (8) trigger, (10) LPI, (6) status/control, stream

            forever begin dma_trig_analysis_fifo_h0.get(dma_trig_tx_h0);
                          process_trigger(dma_trig_tx_h0); end
            // forever begin dma_trig_analysis_fifo_h1.get(dma_trig_tx_h1);
            //               process_trigger(dma_trig_tx_h1); end
            // forever begin dma_trig_analysis_fifo_h2.get(dma_trig_tx_h2);
            //               process_trigger(dma_trig_tx_h2); end
            // forever begin dma_trig_analysis_fifo_h3.get(dma_trig_tx_h3);
            //               process_trigger(dma_trig_tx_h3); end


            forever begin crlp_analysis_fifo_h0.get(crlp_tx_h0);
                          process_lpi(crlp_tx_h0); end
            forever begin dma350_sta_ctrl_analysis_fifo_h0.get(dma350_sc_tx_h0);
                          `uvm_info("process_status_control", $sformatf("process_status_control"),UVM_LOW)
                          process_status_control(dma350_sc_tx_h0); end
            forever begin boot_analysis_fifo_h0.get(boot_tx_h0);
                          process_boot(boot_tx_h0); end
            forever begin axis_slave_analysis_fifo_h0.get(axis_slave_tx_h0);
                          process_stream(axis_slave_tx_h0, 0); end
            forever begin axis_master_analysis_fifo_h0.get(axis_master_tx_h0);
                          process_stream(axis_master_tx_h0, 1); end
        join
    endtask

    //=========================================================================
    // Helpers chung
    //=========================================================================
    function int ch_from_axi(axi5_slave_tx t, bit is_read);
        // DMA-350 ma hoa channel qua *CHID (neu present) hoac AxID.
        int c;
        if (is_read) c = int'(t.archid);
        else         c = int'(t.awchid);
        if (c >= num_channels) begin
            // fallback: dung AxID
            c = is_read ? int'(t.arid) : int'(t.awid);
        end
        if (c >= num_channels) c = 0;
        return c;
    endfunction

    // APB: tach channel & offset (TRM 6.3: channel @ 0x1000+0x100*n)
    function bit apb_is_channel(bit [12:0] a);  return a[12]; endfunction
    function int apb_channel(bit [12:0] a);     return int'(a[10:8]); endfunction
    function bit [7:0] apb_offset(bit [12:0] a); return a[7:0]; endfunction

    //=========================================================================
    // (2) TAI DUNG Y DINH LENH tu register (APB write) + (6) reconcile (read)
    //=========================================================================
    task process_apb(apb_seq_item_master t);
        bit [12:0] a13 = t.paddr[12:0];
        int  ch;
        bit [7:0] off;
        if (!apb_is_channel(a13)) begin
            // 0x0000-0x0FFF : DMA-level (SECCFG/SECCTRL/NSECCTRL/INFO) - security,
            // all-channel stop/pause, poll status. (10)(6) - mo rong tuy nhu cau.
            return;
        end
        ch  = apb_channel(a13);
        off = apb_offset(a13);
        if (ch >= num_channels) return;

        if (t.pwrite) begin
            // ---- register WRITE = cap nhat mirror "y dinh" ----
            ctx[ch].reg_mirror[off] = t.pwdata;
            if (off == CH_CMD) handle_cmd_write(ch, t.pwdata);
            if (off == CH_STATUS) handle_status_w1c(ch, t.pwdata);
        end
        else begin
            // ---- register READ = doi chieu voi model (mirror/live/status) ----
            reconcile_readback(ch, off, t.prdata);
        end
    endtask

    // xu ly ghi CH_CMD (chi track lenh dieu khien sau enable). ENABLE KHONG con
    // snapshot o day: viec chot golden intent duoc dieu khien boi activation-
    // detector qua ch_enabled (process_status_control) => phu cả command-link/boot.
    task handle_cmd_write(int ch, bit [31:0] w);
        if (w[CMD_STOPCMD])    ctx[ch].state = CH_ST_STOPPED;
        if (w[CMD_DISABLECMD]) ctx[ch].state = CH_ST_DISABLED;
        if (w[CMD_PAUSECMD])   ctx[ch].state = CH_ST_PAUSED;
        if (w[CMD_RESUMECMD] && ctx[ch].state == CH_ST_PAUSED)
            ctx[ch].state = CH_ST_ENABLED;
        if (w[CMD_CLEARCMD])   ctx[ch].clear_command();
    endtask

    task handle_status_w1c(int ch, bit [31:0] w);
        // W1C: chi cap nhat mirror status (khong tu sinh giao dich)
        if (w[ST_STAT_DONE])    ctx[ch].reg_mirror[CH_STATUS][ST_STAT_DONE]    = 0;
        if (w[ST_STAT_ERR])     ctx[ch].reg_mirror[CH_STATUS][ST_STAT_ERR]     = 0;
        if (w[ST_STAT_STOPPED]) ctx[ch].reg_mirror[CH_STATUS][ST_STAT_STOPPED] = 0;
    endtask

    //=========================================================================
    // BACKDOOR helpers (peek) : doc trang thai thanh ghi RTL moi luc, khong can
    // giao dich bus. RAL model day du NUM_CHANNELS frame DMACH (ral.dmach[ch]).
    //=========================================================================
    function uvm_reg ral_reg(int ch, bit [7:0] off);
        if (m_ral_dma_model == null)                 return null;
        if (ch < 0 || ch >= m_ral_dma_model.dmach.size()) return null;
        case (off)
            CH_CMD:         return m_ral_dma_model.dmach[ch].ch_cmd;
            CH_STATUS:      return m_ral_dma_model.dmach[ch].ch_status;
            CH_INTREN:      return m_ral_dma_model.dmach[ch].ch_intren;
            CH_CTRL:        return m_ral_dma_model.dmach[ch].ch_ctrl;
            CH_SRCADDR:     return m_ral_dma_model.dmach[ch].ch_srcaddr;
            CH_SRCADDRHI:   return m_ral_dma_model.dmach[ch].ch_srcaddrhi;
            CH_DESADDR:     return m_ral_dma_model.dmach[ch].ch_desaddr;
            CH_DESADDRHI:   return m_ral_dma_model.dmach[ch].ch_desaddrhi;
            CH_XSIZE:       return m_ral_dma_model.dmach[ch].ch_xsize;
            CH_XSIZEHI:     return m_ral_dma_model.dmach[ch].ch_xsizehi;
            CH_SRCTRANSCFG: return m_ral_dma_model.dmach[ch].ch_srctranscfg;
            CH_DESTRANSCFG: return m_ral_dma_model.dmach[ch].ch_destranscfg;
            CH_XADDRINC:    return m_ral_dma_model.dmach[ch].ch_xaddrinc;
            CH_YADDRSTRIDE: return m_ral_dma_model.dmach[ch].ch_yaddrstride;
            CH_FILLVAL:     return m_ral_dma_model.dmach[ch].ch_fillval;
            CH_YSIZE:       return m_ral_dma_model.dmach[ch].ch_ysize;
            CH_SRCTRIGINCFG:return m_ral_dma_model.dmach[ch].ch_srctrigincfg;
            CH_DESTRIGINCFG:return m_ral_dma_model.dmach[ch].ch_destrigincfg;
            CH_TRIGOUTCFG:  return m_ral_dma_model.dmach[ch].ch_trigoutcfg;
            CH_GPOEN0:      return m_ral_dma_model.dmach[ch].ch_gpoen0;
            CH_GPOVAL0:     return m_ral_dma_model.dmach[ch].ch_gpoval0;
            CH_LINKADDR:    return m_ral_dma_model.dmach[ch].ch_linkaddr;
            CH_LINKADDRHI:  return m_ral_dma_model.dmach[ch].ch_linkaddrhi;
            // command-link : thuoc tinh bo nho cua giao dich doc descriptor
            CH_LINKATTR:    return m_ral_dma_model.dmach[ch].ch_linkattr;
            CH_AUTOCFG:     return m_ral_dma_model.dmach[ch].ch_autocfg;
            // template : quyet dinh beat size co duoc toi uu hay khong
            CH_TMPLTCFG:    return m_ral_dma_model.dmach[ch].ch_tmpltcfg;
            CH_SRCTMPLT:    return m_ral_dma_model.dmach[ch].ch_srctmplt;
            CH_DESTMPLT:    return m_ral_dma_model.dmach[ch].ch_destmplt;
            CH_STREAMINTCFG:return m_ral_dma_model.dmach[ch].ch_streamintcfg;
            CH_ERRINFO:     return m_ral_dma_model.dmach[ch].ch_errinfo;
            CH_GPOREAD0:    return m_ral_dma_model.dmach[ch].ch_gporead0;
            default:        return null;
        endcase
    endfunction

    // peek backdoor 1 thanh ghi. ok=0 neu khong co reg / khong co backdoor.
    // Thanh ghi hang so (CH_IIDR/AIDR/BUILDCFG*) co const_reg_backdoor nhung
    // has_hdl_path()==0 -> phai kiem tra get_backdoor() truoc, neu khong se bi
    // bo qua oan va roi ve mirror.
    task ral_peek(int ch, bit [7:0] off, output bit ok, output bit [31:0] val);
        uvm_reg        r = ral_reg(ch, off);
        uvm_status_e   st;
        uvm_reg_data_t d;
        ok = 0; val = 0;
        if (r == null) return;
        if (r.get_backdoor() == null && !r.has_hdl_path()) return; // tranh gia tri rac
        r.peek(st, d);
        if (st == UVM_IS_OK) begin ok = 1; val = d[31:0]; end
    endtask

    // uu tien BACKDOOR peek; fallback frontdoor mirror khi chua co HDL path.
    task peek_or_mirror(int ch, bit [7:0] off, output bit [31:0] val);
        bit ok;
        ral_peek(ch, off, ok, val);
        if (!ok) val = rd_mirror(ch, off);
    endtask

    // ky luat dinh thoi: cho 1 clock sau activation de RTL on dinh config
    // (command-link/boot nap descriptor vao thanh ghi trong vai chu ky).
    task settle_one_clock();
        if (m_sc_vif != null) @(posedge m_sc_vif.clk);
        else                  #0;
    endtask

    // activation : cho 1 clock -> peek config -> golden intent -> predict burst.
    // Goi khi ch_enabled len 1 (phu APB-ENABLE, command-link va autoboot).
    // GIU LAI cho tuong thich nguoc / debug: chot intent NGAY TRONG scoreboard.
    // MAC DINH KHONG DUNG NUA - viec chot intent da chuyen sang component
    // dma350_predict_intent, ket qua vao qua process_intent(). Neu goi ca hai
    // se chot intent 2 lan (predict burst 2 lan -> AR/AW "thua" gia).
    // task do_activation_snapshot(int ch);
    //     settle_one_clock();
    //     snapshot_intent(ch);
    //     ctx[ch].state = CH_ST_ENABLED;
    //     n_commands++;
    //     `uvm_info("SB_CMD", $sformatf(
    //       "CH%0d ACTIVATION (ch_enabled^) -> golden intent %s",
    //       ch, ctx[ch].intent.convert2string()), UVM_MEDIUM)
    //     build_predicted_bursts(ch);
    // endtask

    //=========================================================================
    // (0) NHAN INTENT tu dma350_predict_intent.
    // Predictor da lo phan "dich config" (peek backdoor + giai ma truong), o
    // day scoreboard chi nap intent vao context roi sinh chuoi burst du kien.
    //   valid=1 : channel vua activate  -> nap intent + predict burst
    //   valid=0 : channel vua ket thuc  -> danh dau DONE (khong xoa context de
    //             cac byte/burst con lai van duoc doi chieu not)
    //=========================================================================
    task process_intent(dma_golden_intent t);
        int ch = t.ch_id;
        if (ch < 0 || ch >= num_channels) return;

        if (!t.valid) begin
            if (ctx[ch].state == CH_ST_ENABLED) ctx[ch].state = CH_ST_DONE;
            `uvm_info("SB_INTENT", $sformatf("CH%0d intent het hieu luc", ch), UVM_HIGH)
            return;
        end

        ctx[ch].clear_command();
        ctx[ch].intent          = t;
        ctx[ch].exp_total_bytes = t.total_src_bytes();
        ctx[ch].des_fill_ptr    = t.desaddr;
        ctx[ch].state           = CH_ST_ENABLED;
        n_commands++;

        `uvm_info("SB_INTENT", $sformatf(
          "CH%0d nhan intent tu predictor: src=0x%0h des=0x%0h SRCXSIZE=%0d DESXSIZE=%0d xtype=%0b",
          ch, t.srcaddr, t.desaddr, t.src_xsize, t.des_xsize, t.xtype), UVM_MEDIUM)

        build_predicted_bursts(ch);
    endtask

    // chot toan bo config channel thanh golden intent (doc BACKDOOR peek)
//     task snapshot_intent(int ch);
//         dma_golden_intent gi = dma_golden_intent::type_id::create("gi");
//         bit [31:0] ctrl, xsz, xszhi, xinc, ystr, sctc, dstc, scfg, dcfg, tocfg;
//         bit [31:0] sa_lo, sa_hi, da_lo, da_hi, fillv, ysz, la_lo, la_hi;
//         bit [31:0] stremintcofig;
//         peek_or_mirror(ch, CH_CTRL,         ctrl);
//         peek_or_mirror(ch, CH_XSIZE,        xsz);
//         peek_or_mirror(ch, CH_XSIZEHI,      xszhi);
//         peek_or_mirror(ch, CH_XADDRINC,     xinc);
//         peek_or_mirror(ch, CH_YADDRSTRIDE,  ystr);
//         peek_or_mirror(ch, CH_SRCTRANSCFG,  sctc);
//         peek_or_mirror(ch, CH_DESTRANSCFG,  dstc);
//         peek_or_mirror(ch, CH_SRCTRIGINCFG, scfg);
//         peek_or_mirror(ch, CH_DESTRIGINCFG, dcfg);
//         peek_or_mirror(ch, CH_TRIGOUTCFG,   tocfg);
//         peek_or_mirror(ch, CH_SRCADDR,      sa_lo);
//         peek_or_mirror(ch, CH_SRCADDRHI,    sa_hi);
//         peek_or_mirror(ch, CH_DESADDR,      da_lo);
//         peek_or_mirror(ch, CH_DESADDRHI,    da_hi);
//         peek_or_mirror(ch, CH_FILLVAL,      fillv);
//         peek_or_mirror(ch, CH_YSIZE,        ysz);
//         peek_or_mirror(ch, CH_LINKADDR,     la_lo);
//         peek_or_mirror(ch, CH_LINKADDRHI,   la_hi);
//         peek_or_mirror(ch, CH_STREAMINTCFG, stremintcofig);



//         gi.srcaddr  = {sa_hi, sa_lo};
//         gi.desaddr  = {da_hi, da_lo};
//         gi.src_xsize = {xszhi[15:0],  xsz[15:0]};
//         gi.des_xsize = {xszhi[31:16], xsz[31:16]};
//         gi.src_transize = ctrl[2:0];
//         gi.des_transize = ctrl[2:0];
//         gi.chprio       = ctrl[7:4];
//         gi.xtype        = ctrl[11:9];
//         gi.ytype        = ctrl[14:12];
//         gi.wrap_en      = (ctrl[11:9]==3'b010);
//         gi.fill_en      = (ctrl[11:9]==3'b011);
//         gi.regreloadtype= ctrl[20:18];
//         gi.donetype     = ctrl[23:21];
//         gi.donepauseen  = ctrl[24];
//         gi.usestream    = ctrl[29];
//         gi.src_xaddrinc = $signed(xinc[15:0]);
//         gi.des_xaddrinc = $signed(xinc[31:16]);
//         gi.src_stride   = $signed(ystr[15:0]);
//         gi.des_stride   = $signed(ystr[31:16]);
//         gi.fillval      = rd_mirror(ch, CH_FILLVAL);
//         gi.ysize        = rd_mirror(ch, CH_YSIZE) & 32'hFFFF;
//         gi.src_maxburstlen = sctc[19:16];
//         gi.des_maxburstlen = dstc[19:16];
//         gi.src_cache  = sctc[7:4];  gi.src_inner=sctc[3:0]; gi.src_domain=sctc[9:8];
//         gi.src_prot   = {1'b0, sctc[10], sctc[11]};
//         gi.des_cache  = dstc[7:4];  gi.des_inner=dstc[3:0]; gi.des_domain=dstc[9:8];
//         gi.des_prot   = {1'b0, dstc[10], dstc[11]};
//         gi.use_srctrig= ctrl[25]; gi.use_destrig=ctrl[26]; gi.use_trigout=ctrl[27];
//         gi.srctrig_blksize = scfg[23:16]; gi.destrig_blksize = dcfg[23:16];
//         gi.srctrig_type=scfg[9:8]; gi.destrig_type=dcfg[9:8]; gi.trigout_type=tocfg[9:8];
//         gi.linkaddr    = {rd_mirror(ch,CH_LINKADDRHI), rd_mirror(ch,CH_LINKADDR)};
//         gi.linkaddren  = rd_mirror(ch,CH_LINKADDR) & 32'h1;

//         gi.streamtype = stremintcofig[10:9];

//         ctx[ch].clear_command();

// //----------------fetch config into chanel index ch---------------------------//
//         ctx[ch].intent = gi;
        
//         ctx[ch].exp_total_bytes = gi.total_src_bytes();
//         ctx[ch].des_fill_ptr    = gi.desaddr;
//         // luu snapshot RAW config (khong gom live-counter) cho RO-lock check
//         ctx[ch].cfg_snapshot.delete();
//         ctx[ch].cfg_snapshot[CH_CTRL]         = ctrl;
//         ctx[ch].cfg_snapshot[CH_XSIZEHI]      = xszhi;
//         ctx[ch].cfg_snapshot[CH_XADDRINC]     = xinc;
//         ctx[ch].cfg_snapshot[CH_YADDRSTRIDE]  = ystr;
//         ctx[ch].cfg_snapshot[CH_SRCTRANSCFG]  = sctc;
//         ctx[ch].cfg_snapshot[CH_DESTRANSCFG]  = dstc;
//         ctx[ch].cfg_snapshot[CH_SRCTRIGINCFG] = scfg;
//         ctx[ch].cfg_snapshot[CH_DESTRIGINCFG] = dcfg;
//         ctx[ch].cfg_snapshot[CH_TRIGOUTCFG]   = tocfg;
//         ctx[ch].cfg_snapshot[CH_FILLVAL]      = fillv;
//         ctx[ch].cfg_snapshot[CH_YSIZE]        = ysz;
//     endtask

    function bit [31:0] rd_mirror(int ch, bit [7:0] off);
        if (ctx[ch].reg_mirror.exists(off)) return ctx[ch].reg_mirror[off];
        return 32'h0;
    endfunction

    //=========================================================================
    // (3)(4) PREDICTOR : chot THUOC TINH AXI cho CA MOT COMMAND
    //-------------------------------------------------------------------------
    // Mot lenh = MOT ban ghi rang buoc cho AR + MOT cho AW (+ MOT cho lan fetch
    // command-link ke tiep). Khong con phan ra thanh chuoi burst nen scoreboard
    // KHONG phu thuoc vao viec RTL chia burst ra sao (FIFO, trigger, arbitration
    // deu lam thay doi cach chia) - chi kiem cai ma kien truc BAT BUOC phai dung.
    //=========================================================================

    // do rong bus (byte / log2 byte)
    function int bus_bytes(); return DATA_WIDTH/8;           endfunction
    function int bus_log2();  return $clog2(DATA_WIDTH/8);   endfunction
    // FIFO/2 : gioi han so byte mot burst duoc mang
    function int fifo_half_bytes(); return (fifo_depth_words * bus_bytes()) / 2; endfunction

    function longint min_l(longint a, longint b); return (a < b) ? a : b; endfunction
    function longint max_l(longint a, longint b); return (a > b) ? a : b; endfunction

    //-------------------------------------------------------------------------
    // HINH HOC mot phia cua lenh (theo dung dma350_channel D_IDLE):
    //   sb = src_xsize*unit_s ; db = des_xsize*unit_d
    //   * 2D   (ysize>1) : line_count = ysize, moi line doc sb / ghi db,
    //                      dia chi goc moi line += stride
    //   * WRAP (db>sb>0) : passes = ceil(db/sb), MOI pass doc lai du sb byte tu
    //                      srcaddr -> tong doc = passes*sb, cua so dia chi doc
    //                      van chi la [srcaddr, srcaddr+sb); ghi lien tuc db byte
    //   * CONTINUE       : doc sb, ghi min(sb,db)
    //   * FILL           : doc sb (nguon van duoc doc), ghi db (phan thieu = FILLVAL)
    //-------------------------------------------------------------------------
    function void side_geometry(int ch, bit is_read,
                                output longint base, output longint line_bytes,
                                output longint stride, output int lines,
                                output longint total);
        dma_golden_intent gi = ctx[ch].intent;
        longint sb = longint'(gi.src_xsize) << gi.src_transize;
        longint db = longint'(gi.des_xsize) << gi.des_transize;
        int     passes;
        base = is_read ? gi.srcaddr : gi.desaddr;
        lines = 1; stride = 0;
        if (gi.ysize > 1) begin
            lines      = gi.ysize;
            line_bytes = is_read ? sb : db;
            stride     = is_read ? gi.src_stride : gi.des_stride;
            total      = line_bytes * lines;
        end
        else if (gi.wrap_en && (db > sb) && (sb > 0) && !gi.fill_en) begin
            passes     = int'((db + sb - 1) / sb);
            line_bytes = is_read ? sb : db;   // cua so dia chi cua mot pass
            total      = is_read ? (sb * passes) : db;
        end
        else begin
            line_bytes = is_read ? sb : (gi.fill_en ? db : min_l(sb, db));
            total      = line_bytes;
        end
    endfunction

    //-------------------------------------------------------------------------
    // predict_side : DU DOAN THUOC TINH AXI CHO CA MOT PHIA CUA LENH.
    // Khong con vong while phan ra tung burst - tra ve MOT ban ghi mo ta rang
    // buoc ma MOI AR (is_read=1) / MOI AW (is_read=0) cua lenh phai thoa.
    // KHONG du doan beat size / cach chia burst (xem ghi chu o dma_axi_burst).
    //-------------------------------------------------------------------------
    function dma_axi_burst predict_side(int ch, bit is_read);
        dma_golden_intent gi = ctx[ch].intent;
        dma_axi_burst     bd = dma_axi_burst::type_id::create(is_read?"exp_rd":"exp_wr");
        int signed inc  = is_read ? gi.src_xaddrinc   : gi.des_xaddrinc;
        int  chsize     = is_read ? gi.src_transize   : gi.des_transize;
        int  mbl        = (is_read ? gi.src_maxburstlen : gi.des_maxburstlen) + 1;
        longint base, line_bytes, stride, total;
        longint last_base;
        int  lines;

        side_geometry(ch, is_read, base, line_bytes, stride, lines, total);

        bd.valid       = 1;
        bd.is_read     = is_read;
        bd.is_cmdlink  = 0;
        bd.addr        = base;
        bd.total_bytes = total;

        // ---- (c) cua so dia chi cua CHE DO lenh (1D / 2D / wrap / fill) ------
        // 2D  : tu line dau den line cuoi, stride co the AM (lui) -> min/max
        // wrap: doc lai cung mot vung nguon -> cua so chi bang mot pass
        last_base   = base + stride * (lines - 1);
        bd.addr_lo  = min_l(base, last_base);
        bd.addr_hi  = max_l(base, last_base) + line_bytes;

        // ---- kieu burst ------------------------------------------------------
        bd.fixed = (inc == 0);
        bd.burst = bd.fixed ? BURST_FIXED : BURST_INCR;

        // ---- beat size cua lenh : CHI de log, KHONG dung de so sanh ---------
        // RTL duoc phep gop beat len den do rong bus (toi uu) -> khong doi chieu.
        bd.size = (chsize > bus_log2()) ? bus_log2() : chsize;

        // ---- gioi han do dai burst -------------------------------------------
        // Cac gioi han duoi KHONG phu thuoc beat size ma RTL chon:
        //   * so BEAT <= MAXBURSTLEN+1, va <= 256 (INCR) / 16 (FIXED)
        //   * so BYTE <= FIFO/2 va khong vat qua breakpoint 1KB (kiem o
        //     check_axi_attr voi so byte THUC TE cua burst)
        bd.maxburst_beats = mbl;                       // MAXBURSTLEN + 1
        bd.fifo_max_bytes = fifo_half_bytes();         // FIFO/2 (byte)
        bd.max_beats      = mbl;
        if (bd.max_beats > 256)   bd.max_beats = 256;
        if (bd.fixed && bd.max_beats > 16) bd.max_beats = 16;  // FIXED toi da 16
        if (bd.max_beats < 1)     bd.max_beats = 1;

        // ---- thuoc tinh AXI tu CH_*TRANSCFG + trang thai security channel ----
        //   MEMATTRHI -> AxCACHE, MEMATTRLO -> inner, SHAREATTR -> AxDOMAIN
        //   AxPROT[1] = NONSECATTR | ch_nonsec ; AxPROT[0] = PRIVATTR & ch_priv
        //   AxPROT[2] = 0 (data access; chi command-link moi la instruction)
        bd.cache  = is_read ? gi.src_cache  : gi.des_cache;
        bd.inner  = is_read ? gi.src_inner  : gi.des_inner;
        bd.domain = is_read ? gi.src_domain : gi.des_domain;
        bd.prot   = {1'b0,
                     (is_read ? gi.src_prot[1] : gi.des_prot[1]) | ctx[ch].obs_nonsec,
                     (is_read ? gi.src_prot[0] : gi.des_prot[0]) & ctx[ch].obs_priv};
        bd.qos    = gi.chprio;         // CHPRIO -> AxQOS (cat xuong 4 bit)
        bd.id     = ch;                // AxID = so channel (TRM 4.3.2)
        bd.chid   = ch;                // CHID mac dinh = chi so channel
        bd.wakeup = 1'b1;      // co giao dich dang cho -> AWAKEUP phai len

        `uvm_info("SB_PRED_SIDE", $sformatf("CH%0d %s", ch, bd.convert2string()), UVM_LOW)
        return bd;
    endfunction

    //-------------------------------------------------------------------------
    // predict_cmdlink : DU DOAN AR CUA MOT LAN FETCH DESCRIPTOR.
    //   is_boot=1 : autoboot - dia chi = boot_addr, thuoc tinh = boot_memattr/
    //               boot_shareattr (cung encoding voi LINKMEMATTR*/LINKSHAREATTR
    //               vi autoboot chinh la mot command-link fetch), channel 0
    //               Secure -> AxPROT[1] = 0.
    //   is_boot=0 : command-link - dia chi = CH_LINKADDR (bo 2 bit thap, word
    //               aligned), thuoc tinh = CH_LINKATTR.
    // Chung cho ca hai:
    //   arcmdlink = 1, AxPROT[2] = 1 (instruction access), AxBURST = INCR,
    //   AxSIZE = do rong bus (TRANSIZE full bus cho command-link),
    //   AxLEN+1 <= cmdlink_max_beats va khong vuot breakpoint 1KB.
    //   Security/privilege lay theo TRANG THAI CHANNEL, khong theo transfer
    //   property cua lenh.
    //-------------------------------------------------------------------------
    function dma_axi_burst predict_cmdlink(int ch, bit is_boot, longint faddr,
                                           bit [3:0] memattr_hi, bit [3:0] memattr_lo,
                                           bit [1:0] shareattr);
        dma_axi_burst bd = dma_axi_burst::type_id::create("exp_link");
        bd.valid      = 1;
        bd.is_cmdlink = 1;
        bd.is_boot    = is_boot;
        bd.is_read    = 1;
        bd.addr       = faddr & ~64'h3;     // descriptor word-aligned
        bd.addr_lo    = bd.addr;
        bd.fixed      = 0;
        bd.burst      = BURST_INCR;
        bd.size       = bus_log2();         // full bus width (chi de log)
        // descriptor dai toi da 1 header + 32 word; neu no vat qua breakpoint
        // 1KB thi RTL fetch tiep burst nua -> cua so dia chi bao het vung do.
        bd.total_bytes= longint'(cmdlink_max_beats) << bd.size;
        bd.addr_hi    = bd.addr_lo + bd.total_bytes;
        bd.maxburst_beats = cmdlink_max_beats;   // command-link dung do dai max
        bd.fifo_max_bytes = MAX_BYTES_PER_BURST; // khong di qua FIFO du lieu
        bd.max_beats      = cmdlink_max_beats;
        // thuoc tinh bo nho cua giao dich doc descriptor
        bd.cache      = memattr_hi;
        bd.inner      = memattr_lo;
        bd.domain     = shareattr;
        // AxPROT: [2]=1 instruction (command-link), [1]=secure cua channel bc after reset seccfg = 0 corresponding = secure,
        // [0]=privileged cua channel. Autoboot Ch0 chay Secure -> [1]=0.
        bd.prot       = {1'b1,
                         is_boot ? 1'b0 : ctx[ch].obs_nonsec,
                         ctx[ch].obs_priv};
        bd.qos        = 4'h0;
        bd.id         = ch;            // AxID = so channel dang fetch descriptor
        bd.chid       = ch;
        bd.wakeup     = 1'b1;
        return bd;
    endfunction

    //-------------------------------------------------------------------------
    // arm_cmdlink_from_regs : lenh HIEN TAI co command-link khong?
    // CH_LINKADDR[0] = LINKADDREN. Neu bat thi lan doc co arcmdlink=1 KE TIEP
    // chinh la fetch descriptor cua lenh nay -> chot san du doan de doi.
    //-------------------------------------------------------------------------
    task arm_cmdlink_from_regs(int ch);
        bit [31:0] la_lo, lattr;
        longint    faddr;

        faddr = ctx[ch].intent.linkaddr;
        lattr = ctx[ch].intent.linkattr;
        la_lo[0] = ctx[ch].intent.linkaddren;

        if (!la_lo[0]) begin           // LINKADDREN = 0 -> lenh cuoi cua chuoi
            `uvm_info("SB_PRED_LINK", $sformatf(
              "CH%0d LINKADDREN=0 : khong co lenh ke tiep", ch), UVM_HIGH)
            return;
        end
        // CH_LINKATTR : [3:0] LINKMEMATTRLO, [7:4] LINKMEMATTRHI, [9:8] LINKSHAREATTR
        ctx[ch].exp_link   = predict_cmdlink(ch, 1'b0, faddr,
                                             lattr[7:4], lattr[3:0], lattr[9:8]);
        ctx[ch].link_armed = 1;
        `uvm_info("SB_PRED_LINK", $sformatf(
          "CH%0d lenh hien tai CO command-link -> du doan fetch ke tiep: %s",
          ch, ctx[ch].exp_link.convert2string()), UVM_LOW)
    endtask

    //-------------------------------------------------------------------------
    // Anh xa byte NGUON -> dia chi DICH ky vong (thay dest_base/dest_cap cu).
    // init_data_mapping() chot hinh hoc dong/pass mot lan luc activation, sau do
    // moi byte R goi map_src_byte().
    //-------------------------------------------------------------------------
    function void init_data_mapping(int ch);
        dma_golden_intent gi = ctx[ch].intent;
        longint sbase, sline, sstride, stotal;
        longint dbase, dline, dstride, dtotal;
        int     slines, dlines;
        side_geometry(ch, 1'b1, sbase, sline, sstride, slines, stotal);
        side_geometry(ch, 1'b0, dbase, dline, dstride, dlines, dtotal);
        ctx[ch].des_fixed       = (gi.des_xaddrinc == 0);
        ctx[ch].line_count      = dlines;
        ctx[ch].line_idx        = 0;
        ctx[ch].des_line_base   = dbase;
        ctx[ch].des_line_bytes  = dline;
        ctx[ch].des_line_stride = dstride;
        // so byte NGUON tuong ung mot dong dich (wrap: ca chuoi pass la 1 dong)
        ctx[ch].src_line_bytes  = (dlines > 1) ? sline : stotal;
        ctx[ch].des_ptr         = dbase;
        ctx[ch].des_left        = dline;
        ctx[ch].src_left        = ctx[ch].src_line_bytes;
        ctx[ch].des_fill_ptr    = dbase;
    endfunction

    // dat 1 byte du kien tai vi tri dich hien tai (INCR: theo dia chi, FIXED:
    // theo thu tu qua FIFO so sanh).
    function void put_expected_byte(int ch, bit [7:0] d);
        if (ctx[ch].des_fixed) refmem.exp_fifo.push_back(d);
        else                   refmem.set_expected(ctx[ch].des_ptr, d);
        ctx[ch].des_ptr++;
        ctx[ch].des_left--;
        ctx[ch].bytes_read++;
    endfunction

    // FILL: phan dich con thieu cua dong hien tai duoc bu bang FILLVAL theo lane
    function void pad_fill_line(int ch);
        if (ctx[ch].intent == null || !ctx[ch].intent.fill_en) return;
        while (ctx[ch].des_left > 0)
            put_expected_byte(ch, ctx[ch].intent.fillval[8*(ctx[ch].des_ptr % 4) +: 8]);
    endfunction

    // sang dong 2D / pass ke tiep
    function void next_dest_line(int ch);
        pad_fill_line(ch);
        ctx[ch].line_idx++;
        if (ctx[ch].line_idx < ctx[ch].line_count) begin
            ctx[ch].des_line_base += ctx[ch].des_line_stride;
            ctx[ch].des_ptr        = ctx[ch].des_line_base;
            ctx[ch].des_left       = ctx[ch].des_line_bytes;
            ctx[ch].src_left       = ctx[ch].src_line_bytes;
        end
        else begin
            ctx[ch].des_left = 0; ctx[ch].src_left = 0;
        end
    endfunction

    // mot byte nguon vua doc duoc: do vao dich neu dich con cho, con lai la
    // byte doc-thua (SRCXSIZE > DESXSIZE, pass wrap cuoi) -> drain.
    function void map_src_byte(int ch, bit [7:0] d);
        if (ctx[ch].src_left <= 0) return;             // ngoai pham vi lenh
        if (ctx[ch].des_left > 0) put_expected_byte(ch, d);
        ctx[ch].src_left--;
        if (ctx[ch].src_left == 0) next_dest_line(ch);
    endfunction

    //=========================================================================
    // build_predicted_bursts : chot du doan cho CA LENH (goi 1 lan luc activate)
    //   1) thuoc tinh AR / AW cua lenh
    //   2) anh xa du lieu nguon -> dich
    //   3) neu lenh co command-link : chot san du doan cho lan fetch ke tiep
    //=========================================================================
    task build_predicted_bursts(int ch);
        dma_golden_intent gi = ctx[ch].intent;
        longint sb = longint'(gi.src_xsize) << gi.src_transize;
        longint db = longint'(gi.des_xsize) << gi.des_transize;
        longint rd_total, wr_total;
        longint dummy_base, dummy_line, dummy_stride;
        int     dummy_lines;

        if(sb == 0 && db == 0) axi_operation = NOTHING_OCCUR;
        if(sb == 0 && db != 0) axi_operation = WRITE_ONLY;
        if(sb != 0 && db == 0) axi_operation = READ_ONLY;
        if(sb != 0 && db != 0) axi_operation = WRITE_READ;

        // anh xa du lieu nguon -> dich (dung cho ca fill / wrap / 2D)
        init_data_mapping(ch);

        // STREAM mode (CH_CTRL.USESTREAM): RTL nay KHONG phan biet STREAMTYPE ->
        // luon doc nguon tren AXI (-> str_out) va ghi dich tren AXI (str_in ->).
        // Van du doan AR/AW BINH THUONG (dia chi/so luong) nhung danh dau
        // stream_mode de BO so sanh NOI DUNG byte (du lieu di vong qua stream).
        ctx[ch].stream_mode = gi.usestream;

        // ---- (1) thuoc tinh AR cua lenh ------------------------------------
        if (sb > 0)
            ctx[ch].exp_rd = predict_side(ch, 1'b1);
        // ---- (1) thuoc tinh AW cua lenh ------------------------------------
        if (db > 0)
            ctx[ch].exp_wr = predict_side(ch, 1'b0);

        // tong byte dich ky vong = tong byte GHI (dung cho check_status DONE)
        side_geometry(ch, 1'b0, dummy_base, dummy_line, dummy_stride,
                      dummy_lines, wr_total);
        side_geometry(ch, 1'b1, dummy_base, dummy_line, dummy_stride,
                      dummy_lines, rd_total);
        ctx[ch].exp_total_bytes = wr_total;

        // ---- (2) FILL khong co nguon: toan bo dich la FILLVAL --------------
        if (gi.fill_en && rd_total == 0)
            for (int y = 0; y < ctx[ch].line_count; y++) next_dest_line(ch);

        // ---- (3) lenh nay co command-link khong? ---------------------------
        `uvm_info("SB_PRED", $sformatf(
              "CH%0d LINKADDREN= %0b : khong co lenh ke tiep",ch,gi.linkaddren), UVM_LOW)
        if(gi.linkaddren) arm_cmdlink_from_regs(ch);

        `uvm_info("SB_PRED", $sformatf(
          "CH%0d du doan CA LENH: rd=%0d byte, wr=%0d byte\n  RD: %s\n  WR: %s",
          ch, rd_total, wr_total,
          (ctx[ch].exp_rd != null) ? ctx[ch].exp_rd.convert2string() : "(khong co)",
          (ctx[ch].exp_wr != null) ? ctx[ch].exp_wr.convert2string() : "(khong co)"),
          UVM_LOW)
    endtask

    //=========================================================================
    // KIEM RANG BUOC cho MOT AR/AW quan sat duoc so voi ban ghi du doan cua lenh
    //=========================================================================
    //   chid_sw = AxCHIDVALID : CHID do SW cau hinh (NSEC/SEC_CHCFG.CHID) chu
    //             khong phai chi so channel -> bo qua so CHID trong truong hop do.
    function void check_axi_attr(int ch, dma_axi_burst e, string tag,
                                 longint a, int beats, int size, bit [1:0] burst,
                                 bit [2:0] prot, bit [3:0] cache, bit [1:0] domain,
                                 bit [3:0] inner, int id, int chid, bit chid_sw = 0);
        longint bytes = longint'(beats) << size;
        string  pfx   = $sformatf("CH%0d %s", ch, tag);

        // ---- dia chi : trong cua so cua lenh ------------------------------
        if (e.fixed) begin
            if (a !== e.addr) begin
                `uvm_error("SB_ATTR", $sformatf(
                  "%s addr=0x%0h nhung FIXED phai giu 0x%0h", pfx, a, e.addr))
                err_addr_mismatch++;
            end
        end
        else if (a < e.addr_lo || a >= e.addr_hi) begin
            `uvm_error("SB_ATTR", $sformatf(
              "%s addr=0x%0h ngoai cua so lenh [0x%0h,0x%0h)",
              pfx, a, e.addr_lo, e.addr_hi))
            err_addr_mismatch++;
        end

        // ---- beat size : KHONG doi chieu voi du doan ----------------------
        // RTL duoc phep toi uu (gop beat len ca do rong bus). Chi giu luat AXI:
        // AxSIZE khong duoc lon hon do rong bus.
        if (size > bus_log2()) begin
            `uvm_error("SB_ATTR", $sformatf(
              "%s SIZE=%0d(%0dB) > do rong bus (%0dB)",
              pfx, size, (1<<size), bus_bytes()))
            err_addr_mismatch++;
        end
        else if (size != e.size)
            `uvm_info("SB_ATTR", $sformatf(
              "%s SIZE=%0dB khac beatsize cua lenh (%0dB) - DMA toi uu, khong tinh la loi",
              pfx, (1<<size), (1<<e.size)), UVM_HIGH)

        // ---- do dai burst : MAXBURSTLEN (beat) / FIFO/2 va 1KB (byte) -----
        if (beats > e.max_beats) begin
            `uvm_error("SB_ATTR", $sformatf(
              "%s LEN+1=%0d > gioi han %0d beat (MAXBURSTLEN+1=%0d, INCR<=256 / FIXED<=16)",
              pfx, beats, e.max_beats, e.maxburst_beats))
            err_addr_mismatch++;
        end
        if (bytes > e.fifo_max_bytes) begin
            `uvm_error("SB_ATTR", $sformatf(
              "%s burst mang %0d byte > FIFO/2 = %0d byte",
              pfx, bytes, e.fifo_max_bytes))
            err_addr_mismatch++;
        end
        // breakpoint 1KB: mot burst INCR khong duoc vat qua bien 1KB
        if (!e.fixed && (((a & 64'h3FF) + bytes) > 1024)) begin
            `uvm_error("SB_ATTR", $sformatf(
              "%s burst vat qua breakpoint 1KB: addr=0x%0h bytes=%0d", pfx, a, bytes))
            err_addr_mismatch++;
        end

        // ---- kieu burst ---------------------------------------------------
        if (burst !== e.burst) begin
            `uvm_error("SB_ATTR", $sformatf(
              "%s BURST=%0b nhung du doan %s", pfx, burst, e.fixed ? "FIXED" : "INCR"))
            err_addr_mismatch++;
        end

        // ---- thuoc tinh bo nho / bao mat ----------------------------------
        if (prot !== e.prot) begin
            `uvm_error("SB_ATTR", $sformatf(
              "%s PROT=0b%03b nhung du doan 0b%03b",
              pfx, prot, e.prot))
            err_addr_mismatch++;
        end
        if (domain !== e.domain) begin
            `uvm_error("SB_ATTR", $sformatf(
              "%s DOMAIN=%0b nhung du doan %0b (SHAREATTR)", pfx, domain, e.domain))
            err_addr_mismatch++;
        end
        // AxCACHE cua VIP chi 2 bit -> so 2 bit thap cua MEMATTRHI
        if (cache[1:0] !== e.cache[1:0]) begin
            `uvm_error("SB_ATTR", $sformatf(
              "%s CACHE=0x%0h nhung du doan 0x%0h (MEMATTRHI)", pfx, cache, e.cache))
            err_addr_mismatch++;
        end
        if (inner !== e.inner)
            `uvm_info("SB_ATTR", $sformatf("%s INNER=0x%0h (du doan 0x%0h MEMATTRLO)",
                                           pfx, inner, e.inner), UVM_HIGH)
        // ---- dinh danh channel --------------------------------------------
        // AxID = so channel. CHID (User signal) cung bang chi so channel TRU KHI
        // SW cau hinh CHID rieng (AxCHIDVALID=1) - luc do khong doi chieu.
        if (id !== int'(e.id)) begin
            `uvm_error("SB_ATTR", $sformatf(
              "%s ID=%0d nhung du doan channel %0d", pfx, id, e.id))
            err_addr_mismatch++;
        end
        if ((CHID_WIDTH > 0) && !chid_sw && (chid !== int'(e.chid))) begin
            `uvm_error("SB_ATTR", $sformatf(
              "%s CHID=%0d nhung du doan %0d", pfx, chid, e.chid))
            err_addr_mismatch++;
        end

        // ---- thong ke khoi luong -------------------------------------------
        e.seen_bursts++;
        e.seen_bytes += bytes;
        if (!e.is_cmdlink && e.seen_bytes > e.total_bytes) begin
            `uvm_error("SB_ATTR", $sformatf(
              "%s da chuyen %0d byte > du doan %0d byte cua lenh",
              pfx, e.seen_bytes, e.total_bytes))
            err_addr_mismatch++;
        end
    endfunction

    //=========================================================================
    // (6) PEEK COUNTER tai BIEN BUS-EVENT : "mirror phai khop thuc te bus".
    // Peek live SRCADDR/DESADDR/XSIZE ngay sau moi su kien AR/R/W va kiem
    // don dieu (dia chi khong lui, xsize khong tang) + bounds. Chi kiem khi
    // backdoor hoat dong (ral_peek ok); neu chua co HDL path thi bo qua im lang.
    //=========================================================================
    task peek_check_counters(int ch);
        bit ok_s, ok_d, ok_x;
        bit [31:0] s, d, x;
        dma_golden_intent gi = ctx[ch].intent;
        bit multi_pass;
        if (gi == null) return;
        // WRAP/2D: RTL nap lai SRCADDR = line-base va XSIZE = line-size o MOI
        // pass/line (dma350_channel D_NEXTLINE) -> "dia chi lui"/"xsize tang"
        // la hanh vi DUNG. Chi kiem don dieu + bounds cho lenh 1-pass.
        multi_pass = gi.wrap_en || (gi.ysize > 1);
        ral_peek(ch, CH_SRCADDR, ok_s, s);
        ral_peek(ch, CH_DESADDR, ok_d, d);
        ral_peek(ch, CH_XSIZE,   ok_x, x);
        if (ok_s && !multi_pass) begin
            longint lo = gi.srcaddr;
            longint hi = gi.srcaddr + gi.total_src_bytes();
            if (!gi.fill_en && !(s >= lo[31:0] && s <= hi[31:0])) begin
                `uvm_error("SB_STATUS", $sformatf(
                  "CH%0d live SRCADDR=0x%0h ngoai [0x%0h,0x%0h]", ch, s, lo, hi))
                err_status_mismatch++;
            end
            if (ctx[ch].cnt_peek_valid && !gi.fill_en && s < ctx[ch].last_src_peek) begin
                `uvm_error("SB_STATUS", $sformatf(
                  "CH%0d live SRCADDR lui: 0x%0h < 0x%0h",
                  ch, s, ctx[ch].last_src_peek))
                err_status_mismatch++;
            end
        end
        if (ok_s) ctx[ch].last_src_peek = s;
        if (ok_d) begin
            // DESADDR luon tien (moi mode: wrap dich cung tien block ke tiep)
            if (ctx[ch].cnt_peek_valid && !multi_pass && d < ctx[ch].last_des_peek) begin
                `uvm_error("SB_STATUS", $sformatf(
                  "CH%0d live DESADDR lui: 0x%0h < 0x%0h",
                  ch, d, ctx[ch].last_des_peek))
                err_status_mismatch++;
            end
            ctx[ch].last_des_peek = d;
        end
        if (ok_x) begin
            if (ctx[ch].cnt_peek_valid && !multi_pass
                && int'(x[15:0]) > ctx[ch].last_xsize_peek) begin
                `uvm_error("SB_STATUS", $sformatf(
                  "CH%0d live SRCXSIZE tang: %0d > %0d",
                  ch, x[15:0], ctx[ch].last_xsize_peek))
                err_status_mismatch++;
            end
            ctx[ch].last_xsize_peek = x[15:0];
        end
        if (ok_s || ok_d || ok_x) ctx[ch].cnt_peek_valid = 1;
    endtask

    //=========================================================================
    // (3) COMPARATOR read-address : AR thuc te phai THOA ban ghi thuoc tinh
    // cua lenh (khong con so tung burst mot).
    //=========================================================================
    task process_ar(axi5_slave_tx t, int port);
        int ch = ch_from_axi(t, 1'b1);
        int size = int'(t.arsize);
        int beats = int'(t.arlen) + 1;
        bit [1:0] burst = t.arburst; // enum base la bit[1:0]
        dma_axi_burst obs;

        // ---- COMMAND-LINK / AUTOBOOT FETCH (arcmdlink=1) --------------------
        // Day la lan doc DESCRIPTOR, khong phai du lieu. So voi ban ghi da chot
        // truoc do: hoac tu autoboot (boot_addr + boot_memattr/shareattr), hoac
        // tu LINKADDR/LINKATTR cua lenh vua chay.
        if (t.arcmdlink) begin
            if (!ctx[ch].link_armed || ctx[ch].exp_link == null) begin
                `uvm_error("SB_AR_LINK", $sformatf(
                  "CH%0d: AR command-link @0x%0h nhung KHONG co du doan (lenh truoc khong bat LINKADDREN va cung khong co autoboot)",
                  ch, t.araddr))
                err_addr_mismatch++;
            end
            else begin
                check_axi_attr(ch, ctx[ch].exp_link,
                               ctx[ch].exp_link.is_boot ? "AR BOOT-LINK" : "AR CMD-LINK",
                               t.araddr, beats, size, burst,
                               t.arprot, {2'b00, t.arcache}, t.ardomain, t.arinner,
                               int'(t.arid), int'(t.archid), t.archidvalid);
                `uvm_info("SB_AR_LINK", $sformatf(
                  "CH%0d AR command-link @0x%0h len=%0d size=%0d (du doan %s)",
                  ch, t.araddr, t.arlen, size,
                  ctx[ch].exp_link.convert2string()), UVM_LOW)
                // descriptor co the dai hon 1 burst (RTL fetch tiep). Chi ha co
                // khi da doc het cua so descriptor du doan.
                `uvm_info("SB_AR_LINK", $sformatf("CH%0d R seen_bytes=%0d, total_bytes =%0d", ch, ctx[ch].exp_link.seen_bytes, 
                                                    ctx[ch].exp_link.total_bytes), UVM_MEDIUM)
                if (ctx[ch].exp_link.seen_bytes >= ctx[ch].exp_link.total_bytes) begin
                    ctx[ch].link_armed = 0;
                    `uvm_info("SB_AR_LINK", $sformatf("CH%0d link_armed = 0, axi read command appear in bus", ch), UVM_MEDIUM)
                end
            end
            obs = dma_axi_burst::type_id::create("obs");
            obs.addr=t.araddr; obs.beats=beats; obs.size=size;
            obs.fixed=(burst==BURST_FIXED); obs.is_cmdlink=1;
            ctx[ch].out_rd.push_back(obs);
            ctx[ch].outstanding_rd++;
            return;
        end

        // ---- AR DU LIEU ------------------------------------------------------
        // (7) khong duoc co AR khi config-error hoac chua enable
        if (ctx[ch].state == CH_ST_DISABLED)
            `uvm_warning("SB_ORDER",
                $sformatf("CH%0d: thay AR@0x%0h khi channel DISABLED", ch, t.araddr))
        if (ctx[ch].exp_rd == null) begin
            `uvm_error("SB_AR", $sformatf(
                "CH%0d: AR thua - lenh dang chay khong du doan co doc AXI : addr=0x%0h len=%0d size=%0d",
                ch, t.araddr, t.arlen, size))
            err_addr_mismatch++;
        end
        else begin
            check_axi_attr(ch, ctx[ch].exp_rd, "AR", t.araddr, beats, size, burst,
                           t.arprot, {2'b00, t.arcache}, t.ardomain, t.arinner,
                           int'(t.arid), int'(t.archid), t.archidvalid);
            // AR du lieu KHONG duoc dat arprot[2] (chi command-link la instruction)
            if (t.arprot[2]) begin
                `uvm_error("SB_ATTR", $sformatf(
                  "CH%0d AR du lieu co PROT[2]=1 (instruction) nhung arcmdlink=0", ch))
                err_addr_mismatch++;
            end
            `uvm_info("SB_AR", $sformatf(
              "CH%0d AR @0x%0h len=%0d size=%0d (da doc %0d/%0d byte cua lenh)",
              ch, t.araddr, t.arlen, size,
              ctx[ch].exp_rd.seen_bytes, ctx[ch].exp_rd.total_bytes), UVM_HIGH)
        end
        // outstanding de dat R data (anh xa dich do map_src_byte lo)
        obs = dma_axi_burst::type_id::create("obs");
        obs.addr=t.araddr; obs.beats=beats; obs.size=size;
        obs.fixed=(burst==BURST_FIXED); obs.is_cmdlink=0;
        ctx[ch].out_rd.push_back(obs);
        ctx[ch].outstanding_rd++;
        peek_check_counters(ch);           // (6) peek live counter tai bien AR
    endtask

    //=========================================================================
    // (5) REF-MEMORY : R data = anh nguon -> ap bien doi -> byte dich ky vong
    //=========================================================================
    task process_r(axi5_slave_tx t, int port);
        int ch = ch_from_axi(t, 1'b1);
        dma_axi_burst ob;
        int size, nbeats, bpb;
        longint a;
        if (int'(t.rresp) inside {RESP_SLVERR, RESP_DECERR}) begin
            ctx[ch].seen_rd_resp_err = 1;      // (6) se soi ERRINFO/STAT_ERR
            `uvm_info("SB_R", $sformatf("CH%0d R error resp=%0d", ch, t.rresp), UVM_MEDIUM)
        end
        if (ctx[ch].out_rd.size()==0) return;
        ob = ctx[ch].out_rd.pop_front();
        ctx[ch].outstanding_rd--;
        // (excl) R cua command-link fetch : la descriptor, KHONG dua vao ref-mem
        if (ob.is_cmdlink) begin
            `uvm_info("SB_R", $sformatf(
                "CH%0d R cmd-link descriptor (loai khoi ref-memory)", ch), UVM_HIGH)
            return;
        end
        if (ctx[ch].intent == null) return;
        // STREAM: du lieu nguon di ra str_out (khong toi thang dich); byte ghi
        // dich lay tu str_in. Nen KHONG anh xa R->dich qua ref-memory (tranh
        // mismatch gia). Van dem/peek de kiem tra so luong + tien do.
        if (ctx[ch].stream_mode) begin
            peek_check_counters(ch);
            return;
        end
        size = ob.size; bpb = (1<<size);
        nbeats = t.rdata.size();               // so beat thuc su co data
        a = ob.addr;
        // Anh xa du lieu KHONG con lay tu burst du doan (khong con dest_base/
        // dest_cap): moi byte nguon doc duoc di qua map_src_byte(), no tu dat
        // vao dia chi dich hien tai, tu nhay dong 2D / pass wrap, tu bu FILLVAL
        // khi dich con thieu, va tu drain byte doc-thua (SRCXSIZE > DESXSIZE).
        for (int i=0; i<nbeats; i++) begin
            bit [DATA_WIDTH-1:0] beat = t.rdata[i];
            for (int b=0; b<bpb; b++)
                map_src_byte(ch, beat[8*b +: 8]);
            if (!ob.fixed) a += bpb;
        end

        peek_check_counters(ch);           // (6) peek live counter tai bien R
    endtask

    //=========================================================================
    // (4) COMPARATOR write-address : so AW thuc te voi burst du doan
    //=========================================================================
    task process_aw(axi5_slave_tx t, int port);
        int ch = ch_from_axi(t, 1'b0);
        int size = int'(t.awsize);
        int beats = int'(t.awlen) + 1;
        bit [1:0] burst = t.awburst;
        dma_axi_burst obs;
        if (ctx[ch].exp_wr == null) begin
            `uvm_error("SB_AW", $sformatf(
                "CH%0d: AW thua - lenh dang chay khong du doan co ghi AXI : addr=0x%0h len=%0d size=%0d",
                ch, t.awaddr, t.awlen, size))
            err_addr_mismatch++;
        end
        else begin
            check_axi_attr(ch, ctx[ch].exp_wr, "AW", t.awaddr, beats, size, burst,
                           t.awprot, {2'b00, t.awcache}, t.awdomain, t.awinner,
                           int'(t.awid), int'(t.awchid), t.awchidvalid);
            // AWAKEUP: con giao dich dang cho -> phai duoc keo len
            if (ctx[ch].exp_wr.wakeup && !t.awakeup)
                `uvm_info("SB_AW", $sformatf(
                  "CH%0d AWAKEUP=0 trong khi con giao dich AXI dang cho", ch), UVM_HIGH)
            `uvm_info("SB_AW", $sformatf(
              "CH%0d AW @0x%0h len=%0d size=%0d (da ghi %0d/%0d byte cua lenh)",
              ch, t.awaddr, t.awlen, size,
              ctx[ch].exp_wr.seen_bytes, ctx[ch].exp_wr.total_bytes), UVM_HIGH)
        end
        obs = dma_axi_burst::type_id::create("obs");
        obs.addr=t.awaddr; obs.beats=beats; obs.size=size;
        obs.fixed=(burst==BURST_FIXED); obs.is_cmdlink=0;
        ctx[ch].out_wr.push_back(obs);
        ctx[ch].outstanding_wr++;
        peek_check_counters(ch);           // (6) peek live counter tai bien AW
    endtask

    function bit gi_fill_only(int ch);
        return (ctx[ch].intent != null && ctx[ch].intent.fill_en);
    endfunction

    //=========================================================================
    // (5) COMPARATOR write-data : so byte W thuc te voi ref-memory theo WSTRB
    //=========================================================================
    task process_w(axi5_slave_tx t, int port);
        // ch tu AW outstanding gan nhat (W bam theo AW cung id).
        int ch = pick_wr_channel(t);
        dma_axi_burst ob;
        int size, bpb, nbeats;
        longint a;
        if (ch < 0) return;
        if (ctx[ch].out_wr.size()==0) begin
            `uvm_warning("SB_W", $sformatf("CH%0d: W data khong co AW outstanding", ch))
            return;
        end
        ob = ctx[ch].out_wr.pop_front();
        ctx[ch].outstanding_wr--;
        size = ob.size; bpb = (1<<size);
        nbeats = t.wdata.size();
        a = ob.addr;
        `uvm_info("SB_PROCESS_W",$sformatf("Packet received from axi5_slave_write_data is \n %s",t.sprint()),UVM_LOW)
        for (int i=0; i<nbeats; i++) begin
            bit [DATA_WIDTH-1:0]     beat  = t.wdata[i];
            bit [(DATA_WIDTH/8)-1:0] wstrb = (i < t.wstrb.size()) ? t.wstrb[i] : '1;
            `uvm_info("SB_W", $sformatf("Counter beat written to des %d",i), UVM_LOW)
            // if (gi_fill_only(ch)) begin
            //     // FILL: byte dich ky vong = FILLVAL (theo lane) - dat truc tiep
            //     for (int b=0; b<bpb; b++)
            //         refmem.set_expected(a+b, ctx[ch].intent.fillval[8*(b%4) +: 8]);
            // end

            for (int b=0; b<bpb; b++) begin
                if (wstrb[b]) begin           // xu ly unaligned dau/cuoi qua wstrb
                    // STREAM: byte ghi lay tu str_in (khong tu nguon AXI) -> BO
                    // so sanh noi dung qua ref-memory, chi dem so byte.
                    if (!ctx[ch].stream_mode) begin
                        if(!ob.fixed) begin
                            refmem.set_actual(a+b, beat[8*b +: 8]);
                        end else begin
                            refmem.act_fifo.push_back(beat[8*b +: 8]);
                        end
                    end
                    ctx[ch].bytes_written++;
                    `uvm_info("SB_W", $sformatf("Counter byte written to des %d",ctx[ch].bytes_written), UVM_LOW)
                end
            end

            if (!ob.fixed) a += bpb;
        end

        if(ob.fixed && !ctx[ch].stream_mode) refmem.fixed_compare(size,bpb);
        peek_check_counters(ch);           // (6) peek live counter tai bien W
    endtask

    function int pick_wr_channel(axi5_slave_tx t);
        // uu tien channel co AW outstanding (single-channel: 0)
        foreach (ctx[i])
            if (i < num_channels && ctx[i].out_wr.size() > 0) return i;
        return (num_channels>0)?0:-1;
    endfunction

    //=========================================================================
    // (11) write-response : match B, phat hien response error
    //=========================================================================
    task process_b(axi5_slave_tx t, int port);
        int ch = int'(t.bid);
        if (ch >= num_channels) ch = 0;
        if (int'(t.bresp) inside {RESP_SLVERR, RESP_DECERR}) begin
            ctx[ch].seen_wr_resp_err = 1;
            `uvm_info("SB_B", $sformatf("CH%0d B error resp=%0d", ch, t.bresp), UVM_MEDIUM)
        end
    endtask

    //=========================================================================
    // PHAN LOAI THANH GHI : quyet dinh co so mirror/backdoor duoc khong.
    //=========================================================================
    // (b) CH_STATUS : thanh ghi co trang thai - KHONG so FD/BD, chi log.
    //     Ly do 1 (bit thieu storage): chi 5 bit sticky [20:16] la FLOP; INTR
    //       [3:0], *WAIT [10:8], RESUMEWAIT [21], TRIGINWAIT [26:24] la TO HOP
    //       (build_status) -> backdoor luon doc ve 0.
    //     Ly do 2 (lech truc thoi gian): frontdoor la snapshot tai canh SETUP,
    //       backdoor peek chay sau 1-3 chu ky -> co vua set (DONE) lam lech
    //       ca bit sticky trong transaction chuyen tiep.

    // (c) pha "HW khong ghi vao thanh ghi config" => mirror = RTL, so mirror OK.
    //     Truoc activation (chua ENABLED) hoac da ket thuc (DONE/ERROR/STOPPED/
    //     DISABLED). Trong luc ENABLED/PAUSED : dang operation, config bi RO-lock
    //     boi HW => doi chieu voi cfg_snapshot, khong phai mirror.
    function bit ch_in_static_phase(int ch);
        return !(ctx[ch].state inside {CH_ST_ENABLED, CH_ST_PAUSED});
    endfunction

    //=========================================================================
    // (6) RECONCILE READBACK : doi chieu prdata (frontdoor) voi mo hinh.
    //   Nguyen tac : chi so voi backdoor/mirror khi THANH GHI + PHA cho phep.
    //   * config TINH, pha static (truoc act / sau done) : prdata==peek==mirror
    //   * config TINH, pha operation (ENABLED/PAUSED) : RO-lock -> so cfg_snapshot
    //   * HW-modified (counter/status/errinfo) : KHONG so FD/BD
    //       - CH_STATUS : bo qua so sanh, chi log FD+BD; ngu nghia -> check_status
    //       - live-counter : da peek chu dong o bien AR/R/W, bo qua o day
    //=========================================================================
    task reconcile_readback(int ch, bit [7:0] off, bit [31:0] rd);
        bit ok; bit [31:0] bd;

        case (off)
            //---- STATUS : thanh ghi CO TRANG THAI -> KHONG so FD/BD -----------
            // frontdoor = anh chup tai canh SETUP cua chinh transaction;
            // backdoor  = gia tri song tai thoi diem reconcile (tre 1-3 chu ky).
            // Bit set trong cua so do (vd DONE) lam lech ca bit sticky, nen so
            // truc tiep luon cho ket qua sai lech -> chi LOG hai goc nhin de
            // debug; tinh dung/sai cua co van duoc kiem ngu nghia (check_status).
            CH_STATUS: begin
                ral_peek(ch, off, ok, bd);
                if (ok)
                    `uvm_info("SB_FDBD", $sformatf(
                      "CH%0d STATUS (status-flag reg, bo qua so FD/BD): frontdoor=0x%08h backdoor=0x%08h",
                      ch, rd, bd), UVM_MEDIUM)
                check_status(ch, rd);              // ngu nghia done/err vs bus
            end

            //---- ERRINFO : HW set theo loi thuc -> chi check ngu nghia ----
            CH_ERRINFO: check_errinfo(ch, rd);

            //---- live-counter : HW ghi lien tuc -> da peek o bien bus ----
            CH_SRCADDR, CH_SRCADDRHI, CH_DESADDR, CH_DESADDRHI,
            CH_XSIZE, CH_XSIZEHI, CH_YSIZE: ;

            //---- GPO read : doi chieu qua gpo_ch (status agent) ----
            CH_GPOREAD0: ;

            //---- CH_CMD : write-mostly, bit tu xoa -> bo qua readback ----
            CH_CMD: ;

            //---- config TINH : tuy PHA moi chon nguon compare ----
            default: begin
                if (ch_in_static_phase(ch)) begin
                    // HW khong ghi : prdata phai == backdoor == mirror y dinh SW
                    ral_peek(ch, off, ok, bd);
                    if (ok && rd !== bd)
                        `uvm_error("SB_FDBD", $sformatf(
                          "CH%0d off=0x%02h (static) : frontdoor=0x%08h != backdoor=0x%08h",
                          ch, off, rd, bd))
                    if (ctx[ch].reg_mirror.exists(off) &&
                        rd !== ctx[ch].reg_mirror[off])
                        `uvm_error("SB_MIRROR", $sformatf(
                          "CH%0d off=0x%02h (static) : readback=0x%08h != mirror SW=0x%08h",
                          ch, off, rd, ctx[ch].reg_mirror[off]))
                end
                else begin
                    // dang operation : config bi RO-lock boi HW -> so snapshot,
                    // KHONG so mirror (mirror la y dinh SW, co the da bi ghi de
                    // sau activation ma HW khong nhan cho command dang chay).
                    if (ctx[ch].cfg_snapshot.exists(off) &&
                        rd !== ctx[ch].cfg_snapshot[off])
                        `uvm_warning("SB_ROLOCK", $sformatf(
                          "CH%0d config off=0x%02h doi khi ENABLED : snapshot=0x%08h act=0x%08h",
                          ch, off, ctx[ch].cfg_snapshot[off], rd))
                end
            end
        endcase
    endtask

    // STAT_* phai nhat quan voi dieu kien ket thuc quan sat tren bus.
    // Khi DONE, peek BACKDOOR live-counter de kiem gia tri ket thuc chinh xac.
    task check_status(int ch, bit [31:0] s);
        bit stat_done = s[ST_STAT_DONE];
        bit stat_err  = s[ST_STAT_ERR];
        bit stat_stop = s[ST_STAT_STOPPED];
        bit stat_paus = s[ST_STAT_PAUSED];
        // DONE: da thay du transfer (bytes_written >= exp_total)
        if (stat_done && ctx[ch].exp_total_bytes>0 &&
            ctx[ch].bytes_written < ctx[ch].exp_total_bytes) begin
            `uvm_error("SB_STATUS", $sformatf(
              "CH%0d STAT_DONE nhung moi ghi %0d/%0d byte",
              ch, ctx[ch].bytes_written, ctx[ch].exp_total_bytes))
            err_status_mismatch++;
        end
        // ERR: phai co loi thuc te (bus resp / stream / trigger) quan sat
        if (stat_err && !(ctx[ch].seen_rd_resp_err || ctx[ch].seen_wr_resp_err)) begin
            `uvm_error("SB_STATUS", $sformatf(
              "CH%0d STAT_ERR nhung khong thay loi tren bus", ch))
            err_status_mismatch++;
        end
        if (stat_done) begin ctx[ch].state = CH_ST_DONE; check_done_counters(ch); end
        if (stat_err)  ctx[ch].state = CH_ST_ERROR;
        if (stat_stop) ctx[ch].state = CH_ST_STOPPED;
        if (stat_paus) ctx[ch].state = CH_ST_PAUSED;
    endtask

    // DONE-exact : srcaddr = start + tong byte (INCR) / giu (FIXED); xsize = 0.
    // WRAP 1D van dung (stride nguon=0 -> SRCADDR cuoi = srcaddr + sb).
    // 2D bo qua (SRCADDR cuoi = base line cuoi + sb, phu thuoc stride).
    task check_done_counters(int ch);
        dma_golden_intent gi = ctx[ch].intent;
        bit ok_s, ok_x; bit [31:0] s, x;
        if (gi == null) return;
        if (gi.ysize > 1) return;          // 2D: diem cuoi phu thuoc stride
        ral_peek(ch, CH_SRCADDR, ok_s, s);
        ral_peek(ch, CH_XSIZE,   ok_x, x);
        if (ok_s && !gi.fill_en) begin
            longint expa = gi.srcaddr + (gi.src_xaddrinc==0 ? 0 : gi.line_bytes());
            if (s !== expa[31:0]) begin
                `uvm_error("SB_STATUS", $sformatf(
                  "CH%0d DONE SRCADDR peek=0x%0h exp=0x%0h", ch, s, expa))
                err_status_mismatch++;
            end
        end
        if (ok_x && x[15:0] != 0) begin
            `uvm_error("SB_STATUS", $sformatf(
              "CH%0d DONE nhung SRCXSIZE=%0d != 0", ch, x[15:0]))
            err_status_mismatch++;
        end
    endtask

    // ERRINFO bit phai khop loai loi thuc te
    function void check_errinfo(int ch, bit [31:0] e);
        if (e[EI_AXIRDRESPERR] && !ctx[ch].seen_rd_resp_err) begin
            `uvm_error("SB_STATUS", $sformatf(
              "CH%0d ERRINFO.AXIRDRESPERR nhung R khong loi", ch))
            err_status_mismatch++;
        end
        if (e[EI_AXIWRRESPERR] && !ctx[ch].seen_wr_resp_err) begin
            `uvm_error("SB_STATUS", $sformatf(
              "CH%0d ERRINFO.AXIWRRESPERR nhung B khong loi", ch))
            err_status_mismatch++;
        end
    endfunction

    //=========================================================================
    // (7)(9) STATUS/CONTROL : FSM ch_enabled/err/stopped/paused, GPO, arbitration
    //=========================================================================
    task process_status_control(dma350_sc_item t);
        for (int ch=0; ch<num_channels; ch++) begin
            bit en, er, sp, pa, exp_en;    // khai bao truoc moi statement (SV)
            en = t.ch_enabled[ch];
            er = t.ch_err[ch];
            sp = t.ch_stopped[ch];
            pa = t.ch_paused[ch];

            // (2)(ACTIVATION-DETECTOR) : ch_enabled canh LEN => chot golden intent.
            // Bao phu APB-ENABLE, command-link VA autoboot (khong chi APB ENABLE),
            // vi moi con duong deu ket thuc bang viec ch_enabled len 1.
            // Canh LEN ch_enabled: viec CHOT INTENT da chuyen sang component
            // dma350_predict_intent (intent ve qua process_intent). O day KHONG
            // goi do_activation_snapshot nua - goi ca hai se chot intent 2 lan,
            // build_predicted_bursts chay 2 lan va sinh AR/AW "thua" gia.
            if (en && !ctx[ch].prev_enabled) begin
                `uvm_info("SB_FSM", $sformatf(
                  "CH%0d ch_enabled^ (intent do dma350_predict_intent chot)", ch), UVM_HIGH)
            end
            // ch_enabled canh XUONG (khong con paused) => command ket thuc
            if (!en && ctx[ch].prev_enabled && ctx[ch].state == CH_ST_ENABLED)
                ctx[ch].state = CH_ST_DONE;
            ctx[ch].prev_enabled = en;

            // (7) doi chieu FSM suy tu scoreboard vs ch_enabled thuc te
            exp_en = (ctx[ch].state == CH_ST_ENABLED || ctx[ch].state == CH_ST_PAUSED);
            if (en != exp_en)
                `uvm_info("SB_FSM", $sformatf(
                  "CH%0d ch_enabled=%0b (mong doi %0b theo state=%s)",
                  ch, en, exp_en, ctx[ch].state.name()), UVM_HIGH)
            ctx[ch].obs_enabled = en; ctx[ch].obs_err = er;
            ctx[ch].obs_stopped = sp; ctx[ch].obs_paused = pa;
            // security/privilege cua channel -> AxPROT[1:0] cua ca data lan
            // command-link (attribute command-link dung state cua channel).
            ctx[ch].obs_priv    = t.ch_priv[ch];
            ctx[ch].obs_nonsec  = t.ch_nonsec[ch];
            if (er) ctx[ch].state = CH_ST_ERROR;
            // (4) GPO: gia tri gpo_ch phai khop GPOVAL0 & GPOEN0 khi USEGPO
            check_gpo(ch, t.gpo_ch[ch]);
        end
    endtask

    function void check_gpo(int ch, bit [`DMA350_SC_MAX_GPO_WIDTH-1:0] gpo);
        bit [31:0] gpoen  = rd_mirror(ch, CH_GPOEN0);
        bit [31:0] gpoval = rd_mirror(ch, CH_GPOVAL0);
        bit [31:0] ctrl   = rd_mirror(ch, CH_CTRL);
        if (!ctrl[28]) return;             // USEGPO=0 : gpo giu gia tri, khong soi
        for (int b=0; b<`DMA350_SC_MAX_GPO_WIDTH; b++)
            if (gpoen[b] && (gpo[b] !== gpoval[b]))
                `uvm_warning("SB_GPO", $sformatf(
                  "CH%0d GPO[%0d]=%0b nhung GPOVAL=%0b (GPOEN=1)", ch, b, gpo[b], gpoval[b]))
    endfunction

    //=========================================================================
    // (8) TRIGGER & flow-control : doi chieu handshake, acktype dung ngu canh
    //=========================================================================
    task process_trigger(dma_trig_item t);
        // acktype khong bao gio la RESERVED (chi OKAY/DENY/LASTOKAY hop le)
        bit [1:0] ackv = t.observed_acktype;
        if (!(ackv inside {TRIGACK_OKAY, TRIGACK_DENY, TRIGACK_LASTOKAY})) begin
            `uvm_error("SB_TRIG", $sformatf(
              "acktype RESERVED/khong hop le = %0b (req=%s)",
              ackv, t.observed_reqtype.name()))
            err_trigger++;
        end
        // ack cung chu ky req = vi pham 4-phase
        if (t.comb_ack_seen) begin
            `uvm_error("SB_TRIG", "trigger ack combinational cung cycle voi req (vi pham 4-phase)")
            err_trigger++;
        end
        `uvm_info("SB_TRIG", t.convert2string(), UVM_HIGH)
    endtask

    //=========================================================================
    // (10) SECURITY & POWER : P/Q accept/deny khop trang thai hoat dong
    //=========================================================================
    task process_lpi(crlp_seq_item t);
        bit any_busy = 0;
        foreach (ctx[i])
            if (i<num_channels && (ctx[i].state==CH_ST_ENABLED ||
                ctx[i].outstanding_rd>0 || ctx[i].outstanding_wr>0)) any_busy = 1;
        // P-Channel: low-power/OFF chi accept khi idle; ON luon accept
        if (t.op == OP_PCH_REQ) begin
            bit is_on = (t.pstate == PSTATE_ON_FULL);
            if (!is_on && any_busy && t.rsp == RSP_ACCEPT) begin
                `uvm_error("SB_LPI", $sformatf(
                  "P-Channel ACCEPT low-power (pstate=0x%0h) khi DMAC busy", t.pstate))
                err_lpi++;
            end
            if (is_on && t.rsp == RSP_DENY) begin
                `uvm_error("SB_LPI", "P-Channel DENY trang thai ON (phai luon accept)")
                err_lpi++;
            end
        end
        `uvm_info("SB_LPI", $sformatf("LPI op=%s rsp=%s busy=%0b",
                  t.op.name(), t.rsp.name(), any_busy), UVM_HIGH)
    endtask

    //=========================================================================
    // (2) BOOT : autoboot nap golden intent cho Ch0
    //=========================================================================
    // AUTOBOOT: boot_en=1 => Ch0 tu fetch DESCRIPTOR tai boot_addr ngay sau
    // reset, KHONG can SW ghi thanh ghi nao. Lan doc arcmdlink=1 DAU TIEN cua
    // Ch0 chinh la lan doc command description do -> chot du doan ngay day.
    // boot_memattr[7:0] dung chung encoding voi LINKMEMATTRHI+LINKMEMATTRLO va
    // boot_shareattr[1:0] voi LINKSHAREATTR (cung mot loai giao dich: descriptor
    // fetch), nen dung chung predict_cmdlink().
    task process_boot(boot_seq_item t);
        bit [7:0] ma;
        if (!t.boot_en) begin
            boot_en_seen = 0;
            `uvm_info("SB_BOOT", "boot_en=0 : khong co autoboot", UVM_HIGH)
            return;
        end
        ma              = t.memattr();
        boot_en_seen    = 1;
        boot_fetch_addr = {t.boot_addr, 2'b00};
        boot_memattr    = ma;
        boot_shareattr  = t.shareattr;
        // Ch0 boot Secure (TRM 4.9.1) -> AxPROT[1]=0, xu ly trong predict_cmdlink
        ctx[0].exp_link   = predict_cmdlink(0, 1'b1, boot_fetch_addr,
                                            ma[7:4], ma[3:0], t.shareattr);
        ctx[0].link_armed = 1;
        `uvm_info("SB_BOOT", $sformatf(
          "autoboot Ch0: doc command description @0x%0h, du doan %s",
          boot_fetch_addr, ctx[0].exp_link.convert2string()), UVM_LOW)
    endtask

    //=========================================================================
    // AXI-Stream : DPU / stream path (usestream) - hung data stream lam nguon/dich
    //=========================================================================
    task process_stream(axis_seq_item t, bit is_master);
        // is_master=1 : str_out (DMA -> peripheral) = ghi qua stream
        // is_master=0 : str_in  (peripheral -> DMA) = doc qua stream
        `uvm_info("SB_STREAM", $sformatf("stream %s last=%0b nbytes=%0d",
                  is_master?"OUT":"IN", t.last, t.data.size()), UVM_HIGH)
        // Khi usestream: stream OUT thay the W-channel; co the map vao ref-memory
        // theo desaddr neu can (mo rong tuy DPU model).
    endtask

    //=========================================================================
    // (12) END-OF-TEST : kiem tra hoan tat, khong con outstanding, ref-mem sach
    //=========================================================================
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        // Du doan la theo CA LENH: cuoi test tong byte da thay tren bus phai
        // bang tong byte du doan cua lenh cuoi cung (thieu = lenh chua chay het).
        foreach (ctx[ch]) begin
            if (ch >= num_channels) continue;
            if (ctx[ch].exp_rd != null && ctx[ch].exp_rd.seen_bytes < ctx[ch].exp_rd.total_bytes)
                `uvm_error("SB_EOT", $sformatf(
                  "CH%0d read-side moi thay %0d/%0d byte tren bus (%0d burst)",
                  ch, ctx[ch].exp_rd.seen_bytes, ctx[ch].exp_rd.total_bytes,
                  ctx[ch].exp_rd.seen_bursts))
            if (ctx[ch].exp_wr != null && ctx[ch].exp_wr.seen_bytes < ctx[ch].exp_wr.total_bytes)
                `uvm_error("SB_EOT", $sformatf(
                  "CH%0d write-side moi thay %0d/%0d byte tren bus (%0d burst)",
                  ch, ctx[ch].exp_wr.seen_bytes, ctx[ch].exp_wr.total_bytes,
                  ctx[ch].exp_wr.seen_bursts))
            if (ctx[ch].link_armed)
                `uvm_error("SB_EOT", $sformatf(
                  "CH%0d da du doan mot lan fetch command-link (%s) nhung KHONG thay AR arcmdlink tren bus",
                  ch, (ctx[ch].exp_link != null) ? ctx[ch].exp_link.convert2string() : ""))
            if (ctx[ch].outstanding_rd != 0 || ctx[ch].outstanding_wr != 0)
                `uvm_error("SB_EOT", $sformatf(
                  "CH%0d con outstanding rd=%0d wr=%0d", ch,
                  ctx[ch].outstanding_rd, ctx[ch].outstanding_wr))
        end
        refmem.report_dangling(this);   // byte du kien/thua chua khop
    endfunction

    //=========================================================================
    // report : bao cao co cau
    //=========================================================================
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SB_REPORT", $sformatf(
          "\n==================== DMA SCOREBOARD SUMMARY ====================\n  commands observed      : %0d\n  data bytes matched     : %0d\n  data byte mismatches   : %0d\n  AR/AW addr mismatches  : %0d\n  status/counter mism.   : %0d\n  trigger errors         : %0d\n  LPI/power errors       : %0d\n===============================================================",
          n_commands, refmem.match, refmem.mismatches,
          err_addr_mismatch, err_status_mismatch, err_trigger, err_lpi), UVM_LOW)
    endfunction

endclass
`endif