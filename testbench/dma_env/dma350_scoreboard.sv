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

    typedef enum { CH_ST_DISABLED, CH_ST_ENABLED, CH_ST_PAUSED,
                   CH_ST_DONE, CH_ST_STOPPED, CH_ST_ERROR } ch_state_e;


//=============================================================================
// dma_axi_burst : mot mo ta burst AXI ky vong (predictor sinh ra)
//=============================================================================
class dma_axi_burst extends uvm_object;
    bit [63:0] addr;
    int        beats;   // so beat
    int        size;    // log2 bytes/beat (AxSIZE)
    bit        fixed;    // 1 = FIXED, 0 = INCR
    bit        is_cmdlink; // 1 = fetch descriptor command-link (loai khoi data path)
    `uvm_object_utils(dma_axi_burst)
    function new(string name="dma_axi_burst"); super.new(name); endfunction
    function int len();      return beats-1;           endfunction   // AxLEN
    function int bytes();    return beats << size;      endfunction
    function string convert2string();
        return $sformatf("addr=0x%0h len=%0d size=%0d(%0dB) burst=%s",
            addr, len(), size, (1<<size), fixed?"FIXED":"INCR");
    endfunction
endclass


//=============================================================================
// dma_golden_intent : snapshot cau hinh 1 command tai thoi diem ENABLECMD.
// Day la "y dinh" chot cung; predictor va ref-memory doc tu day.
//=============================================================================
class dma_golden_intent extends uvm_object;
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

    `uvm_object_utils(dma_golden_intent)
    function new(string name="dma_golden_intent"); super.new(name); endfunction

    // tong so byte 1D (mot dong) va toan transfer (co 2D)
    function int line_bytes(); return src_xsize << src_transize; endfunction
    function int total_src_bytes();
        return line_bytes() * ((ytype!=0 && ysize>0) ? ysize : 1);
    endfunction
endclass


//=============================================================================
// dma_ch_ctx : context per-channel. Giu golden intent hien hanh, FSM, hang doi
// outstanding, con tro tien do va thong ke.
//=============================================================================
class dma_ch_ctx extends uvm_object;
    int              chan_id;
    ch_state_e       state = CH_ST_DISABLED;
    dma_golden_intent intent;             // command dang chay (null neu idle)

    // predictor: chuoi burst AR/AW ky vong (pop khi thay tren bus)
    dma_axi_burst    exp_rd[$];
    dma_axi_burst    exp_wr[$];

    // outstanding: pairing AR->R va AW->W de dat byte vao/ra ref-memory
    dma_axi_burst    out_rd[$];           // AR da phat, cho R data
    dma_axi_burst    out_wr[$];           // AW da phat, cho W data

    // stream byte nguon (theo thu tu doc) -> nap vao ref-memory dich
    bit [7:0]        src_stream[$];
    longint          des_fill_ptr;         // con tro byte dich ke tiep can nap ky vong

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
    bit              prev_enabled;         // activation-detector (rising edge ch_enabled)

    // peek counter gan nhat (kiem tra don dieu + bounds tai bien bus-event)
    bit              cnt_peek_valid;
    longint          last_src_peek, last_des_peek;
    int              last_xsize_peek;

    // co loi da inject / quan sat
    bit              seen_rd_resp_err, seen_wr_resp_err;

    `uvm_object_utils(dma_ch_ctx)
    function new(string name="dma_ch_ctx"); super.new(name); endfunction

    function void clear_command();
        intent = null;
        exp_rd.delete(); exp_wr.delete();
        out_rd.delete(); out_wr.delete();
        src_stream.delete();
        des_fill_ptr = 0;
        bytes_read = 0; bytes_written = 0; exp_total_bytes = 0;
    endfunction
endclass


//=============================================================================
// dma_ref_memory : reference-memory trung gian (byte @ address).
// exp[addr]=byte du kien ghi ; act[addr]=byte thuc te ghi.
//=============================================================================
class dma_ref_memory extends uvm_object;
    bit [7:0] exp   [longint];
    bit       exp_v [longint];
    bit [7:0] act   [longint];
    bit       act_v [longint];
    int       mismatches = 0;
    int       match    = 0;

    `uvm_object_utils(dma_ref_memory)
    function new(string name="dma_ref_memory"); super.new(name); endfunction

    // predictor/ref-model dat byte du kien tai dia chi dich
    function void set_expected(longint a, bit [7:0] d);
        exp[a] = d; exp_v[a] = 1;
        try_compare(a);
    endfunction

    // comparator: byte thuc te tu W-channel (chi khi wstrb=1)
    function void set_actual(longint a, bit [7:0] d);
        act[a] = d; act_v[a] = 1;
        try_compare(a);
    endfunction

    // so khop theo NOI DUNG tai dia chi (khong theo thu tu thoi gian)
    function void try_compare(longint a);
        if (exp_v[a] && act_v[a]) begin
            if (exp[a] === act[a]) match++;
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

    dma_trig_item dma_trig_tx_h0;
    uvm_tlm_analysis_fifo#(dma_trig_item) dma_trig_analysis_fifo_h0;

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
        dma_trig_analysis_fifo_h0    = new("dma_trig_analysis_fifo_h0",this);
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
            forever begin crlp_analysis_fifo_h0.get(crlp_tx_h0);
                          process_lpi(crlp_tx_h0); end
            forever begin dma350_sta_ctrl_analysis_fifo_h0.get(dma350_sc_tx_h0);
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
    // giao dich bus. RAL hien chi model channel 0 (ral.dmach) -> mo rong
    // ral_reg() khi RAL them block channel khac.
    //=========================================================================
    function uvm_reg ral_reg(int ch, bit [7:0] off);
        if (m_ral_dma_model == null) return null;
        if (ch != 0)                 return null;   // RAL moi model channel 0
        case (off)
            CH_CMD:         return m_ral_dma_model.dmach.ch_cmd;
            CH_STATUS:      return m_ral_dma_model.dmach.ch_status;
            CH_INTREN:      return m_ral_dma_model.dmach.ch_intren;
            CH_CTRL:        return m_ral_dma_model.dmach.ch_ctrl;
            CH_SRCADDR:     return m_ral_dma_model.dmach.ch_srcaddr;
            CH_SRCADDRHI:   return m_ral_dma_model.dmach.ch_srcaddrhi;
            CH_DESADDR:     return m_ral_dma_model.dmach.ch_desaddr;
            CH_DESADDRHI:   return m_ral_dma_model.dmach.ch_desaddrhi;
            CH_XSIZE:       return m_ral_dma_model.dmach.ch_xsize;
            CH_XSIZEHI:     return m_ral_dma_model.dmach.ch_xsizehi;
            CH_SRCTRANSCFG: return m_ral_dma_model.dmach.ch_srctranscfg;
            CH_DESTRANSCFG: return m_ral_dma_model.dmach.ch_destranscfg;
            CH_XADDRINC:    return m_ral_dma_model.dmach.ch_xaddrinc;
            CH_YADDRSTRIDE: return m_ral_dma_model.dmach.ch_yaddrstride;
            CH_FILLVAL:     return m_ral_dma_model.dmach.ch_fillval;
            CH_YSIZE:       return m_ral_dma_model.dmach.ch_ysize;
            CH_SRCTRIGINCFG:return m_ral_dma_model.dmach.ch_srctrigincfg;
            CH_DESTRIGINCFG:return m_ral_dma_model.dmach.ch_destrigincfg;
            CH_TRIGOUTCFG:  return m_ral_dma_model.dmach.ch_trigoutcfg;
            CH_GPOEN0:      return m_ral_dma_model.dmach.ch_gpoen0;
            CH_GPOVAL0:     return m_ral_dma_model.dmach.ch_gpoval0;
            CH_LINKADDR:    return m_ral_dma_model.dmach.ch_linkaddr;
            CH_LINKADDRHI:  return m_ral_dma_model.dmach.ch_linkaddrhi;
            CH_ERRINFO:     return m_ral_dma_model.dmach.ch_errinfo;
            CH_GPOREAD0:    return m_ral_dma_model.dmach.ch_gporead0;
            default:        return null;
        endcase
    endfunction

    // peek backdoor 1 thanh ghi. ok=0 neu khong co reg / khong co HDL path.
    task ral_peek(int ch, bit [7:0] off, output bit ok, output bit [31:0] val);
        uvm_reg        r = ral_reg(ch, off);
        uvm_status_e   st;
        uvm_reg_data_t d;
        ok = 0; val = 0;
        if (r == null)          return;
        if (!r.has_hdl_path())  return;   // path sai/thieu -> tranh gia tri rac
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
    task do_activation_snapshot(int ch);
        settle_one_clock();
        snapshot_intent(ch);
        ctx[ch].state = CH_ST_ENABLED;
        n_commands++;
        `uvm_info("SB_CMD", $sformatf(
          "CH%0d ACTIVATION (ch_enabled^) -> golden intent %s",
          ch, ctx[ch].intent.convert2string()), UVM_MEDIUM)
        build_predicted_bursts(ch);
    endtask

    // chot toan bo config channel thanh golden intent (doc BACKDOOR peek)
    task snapshot_intent(int ch);
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

        gi.srcaddr  = {sa_hi, sa_lo};
        gi.desaddr  = {da_hi, da_lo};
        gi.src_xsize = {xszhi[15:0],  xsz[15:0]};
        gi.des_xsize = {xszhi[31:16], xsz[31:16]};
        gi.src_transize = ctrl[2:0];
        gi.des_transize = ctrl[2:0];
        gi.chprio       = ctrl[7:4];
        gi.xtype        = ctrl[11:9];
        gi.ytype        = ctrl[14:12];
        gi.wrap_en      = (ctrl[11:9]==3'b010);
        gi.fill_en      = (ctrl[11:9]==3'b011);
        gi.regreloadtype= ctrl[20:18];
        gi.donetype     = ctrl[23:21];
        gi.donepauseen  = ctrl[24];
        gi.usestream    = ctrl[29];
        gi.src_xaddrinc = $signed(xinc[15:0]);
        gi.des_xaddrinc = $signed(xinc[31:16]);
        gi.src_stride   = $signed(ystr[15:0]);
        gi.des_stride   = $signed(ystr[31:16]);
        gi.fillval      = rd_mirror(ch, CH_FILLVAL);
        gi.ysize        = rd_mirror(ch, CH_YSIZE) & 32'hFFFF;
        gi.src_maxburstlen = sctc[19:16];
        gi.des_maxburstlen = dstc[19:16];
        gi.src_cache  = sctc[7:4];  gi.src_inner=sctc[3:0]; gi.src_domain=sctc[9:8];
        gi.src_prot   = {1'b0, sctc[10], sctc[11]};
        gi.des_cache  = dstc[7:4];  gi.des_inner=dstc[3:0]; gi.des_domain=dstc[9:8];
        gi.des_prot   = {1'b0, dstc[10], dstc[11]};
        gi.use_srctrig= ctrl[25]; gi.use_destrig=ctrl[26]; gi.use_trigout=ctrl[27];
        gi.srctrig_blksize = scfg[23:16]; gi.destrig_blksize = dcfg[23:16];
        gi.srctrig_type=scfg[9:8]; gi.destrig_type=dcfg[9:8]; gi.trigout_type=tocfg[9:8];
        gi.linkaddr    = {rd_mirror(ch,CH_LINKADDRHI), rd_mirror(ch,CH_LINKADDR)};
        gi.linkaddren  = rd_mirror(ch,CH_LINKADDR) & 32'h1;

        ctx[ch].clear_command();
        ctx[ch].intent = gi;
        ctx[ch].exp_total_bytes = gi.total_src_bytes();
        ctx[ch].des_fill_ptr    = gi.desaddr;
        // luu snapshot RAW config (khong gom live-counter) cho RO-lock check
        ctx[ch].cfg_snapshot.delete();
        ctx[ch].cfg_snapshot[CH_CTRL]         = ctrl;
        ctx[ch].cfg_snapshot[CH_XSIZEHI]      = xszhi;
        ctx[ch].cfg_snapshot[CH_XADDRINC]     = xinc;
        ctx[ch].cfg_snapshot[CH_YADDRSTRIDE]  = ystr;
        ctx[ch].cfg_snapshot[CH_SRCTRANSCFG]  = sctc;
        ctx[ch].cfg_snapshot[CH_DESTRANSCFG]  = dstc;
        ctx[ch].cfg_snapshot[CH_SRCTRIGINCFG] = scfg;
        ctx[ch].cfg_snapshot[CH_DESTRIGINCFG] = dcfg;
        ctx[ch].cfg_snapshot[CH_TRIGOUTCFG]   = tocfg;
        ctx[ch].cfg_snapshot[CH_FILLVAL]      = fillv;
        ctx[ch].cfg_snapshot[CH_YSIZE]        = ysz;
    endtask

    function bit [31:0] rd_mirror(int ch, bit [7:0] off);
        if (ctx[ch].reg_mirror.exists(off)) return ctx[ch].reg_mirror[off];
        return 32'h0;
    endfunction

    //=========================================================================
    // (3)(4) PREDICTOR : phan ra golden intent thanh chuoi burst AR/AW ky vong
    // Port thuat toan calc_beats tu dma350_burst.sv (1KB breakpoint, MAX_BYTES,
    // AxLEN<=256, MAXBURSTLEN, FIXED<=16).
    //=========================================================================
    function int calc_beats(int rem, longint cur_addr, int size,
                            bit fixed, int max_beats);
        int m = rem;
        int b1k, bmax;
        if (fixed) begin
            if (m > 16) m = 16;
        end else begin
            b1k  = (1024 - (cur_addr & 32'h3FF)) >> size;     // beats toi bien 1KB
            bmax = MAX_BYTES_PER_BURST >> size;               // cap payload
            if (b1k  < m) m = b1k;
            if (bmax < m) m = bmax;
            if (m > 256)  m = 256;
        end
        if (max_beats < m) m = max_beats;
        if (m <= 0) m = 1;
        return m;
    endfunction

    function void predict_side(int ch, longint start_addr, int total_beats,
                               int size, bit fixed, int max_beats,
                               int signed elem_inc, bit is_read);
        longint    cur = start_addr;
        int        rem = total_beats;
        dma_axi_burst bd;
        // neu increment=0 -> FIXED (dia chi khong tang)
        bit        eff_fixed = fixed || (elem_inc == 0);
        while (rem > 0) begin
            int nb = calc_beats(rem, cur, size, eff_fixed, max_beats);
            bd = dma_axi_burst::type_id::create("bd");
            bd.addr = cur; bd.beats = nb; bd.size = size; bd.fixed = eff_fixed;
            if (is_read) ctx[ch].exp_rd.push_back(bd);
            else         ctx[ch].exp_wr.push_back(bd);
            if (!eff_fixed) cur += (nb << size);
            rem -= nb;

            
        end
    endfunction

    function void build_predicted_bursts(int ch);
        dma_golden_intent gi = ctx[ch].intent;
        int lines = (gi.ytype!=0 && gi.ysize>0) ? gi.ysize : 1;
        int max_rd = gi.src_maxburstlen + 1;
        int max_wr = gi.des_maxburstlen + 1;
        longint sa = gi.srcaddr, da = gi.desaddr;
        if (gi.usestream) return;   // stream path: du doan qua AXI-Stream, khong AXI-M
        for (int y=0; y<lines; y++) begin
            // moi dong: src_xsize beat kich thuoc src_transize
            if (!gi.fill_en)   // FILL khong doc nguon
                predict_side(ch, sa, gi.src_xsize, gi.src_transize,
                             1'b0, max_rd, gi.src_xaddrinc, 1'b1);
            predict_side(ch, da, gi.des_xsize, gi.des_transize,
                         1'b0, max_wr, gi.des_xaddrinc, 1'b0);
            sa += gi.src_stride;   // buoc dong 2D (byte)
            da += gi.des_stride;
        end
        `uvm_info("SB_PRED", $sformatf("CH%0d predicted %0d rd-burst, %0d wr-burst (%0d byte)",
                  ch, ctx[ch].exp_rd.size(), ctx[ch].exp_wr.size(),
                  ctx[ch].exp_total_bytes), UVM_HIGH)
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
        if (gi == null) return;
        ral_peek(ch, CH_SRCADDR, ok_s, s);
        ral_peek(ch, CH_DESADDR, ok_d, d);
        ral_peek(ch, CH_XSIZE,   ok_x, x);
        if (ok_s) begin
            longint lo = gi.srcaddr;
            longint hi = gi.srcaddr + gi.total_src_bytes();
            if (!gi.fill_en && !(s >= lo[31:0] && s <= hi[31:0]))
                mism_status($sformatf("CH%0d live SRCADDR=0x%0h ngoai [0x%0h,0x%0h]",
                                      ch, s, lo, hi));
            if (ctx[ch].cnt_peek_valid && !gi.fill_en && s < ctx[ch].last_src_peek)
                mism_status($sformatf("CH%0d live SRCADDR lui: 0x%0h < 0x%0h",
                                      ch, s, ctx[ch].last_src_peek));
            ctx[ch].last_src_peek = s;
        end
        if (ok_d) begin
            if (ctx[ch].cnt_peek_valid && d < ctx[ch].last_des_peek)
                mism_status($sformatf("CH%0d live DESADDR lui: 0x%0h < 0x%0h",
                                      ch, d, ctx[ch].last_des_peek));
            ctx[ch].last_des_peek = d;
        end
        if (ok_x) begin
            if (ctx[ch].cnt_peek_valid && int'(x[15:0]) > ctx[ch].last_xsize_peek)
                mism_status($sformatf("CH%0d live SRCXSIZE tang: %0d > %0d",
                                      ch, x[15:0], ctx[ch].last_xsize_peek));
            ctx[ch].last_xsize_peek = x[15:0];
        end
        if (ok_s || ok_d || ok_x) ctx[ch].cnt_peek_valid = 1;
    endtask

    //=========================================================================
    // (3) COMPARATOR read-address : so AR thuc te voi burst du doan
    //=========================================================================
    task process_ar(axi5_slave_tx t, int port);
        int ch = ch_from_axi(t, 1'b1);
        int size = int'(t.arsize);
        int beats = int'(t.arlen) + 1;
        bit [1:0] burst = t.arburst; // enum base la bit[1:0]
        dma_axi_burst exp, obs;

        // (excl) command-link descriptor fetch (arcmdlink=1) : KHONG phai data
        // read. Config lay bang BACKDOOR peek nen loai khoi so sanh burst; chi
        // push marker de giu dong bo pairing voi R-channel.
        if (t.arcmdlink) begin
            obs = dma_axi_burst::type_id::create("obs");
            obs.addr=t.araddr; obs.beats=beats; obs.size=size;
            obs.fixed=(burst==BURST_FIXED); obs.is_cmdlink=1;
            ctx[ch].out_rd.push_back(obs);
            ctx[ch].outstanding_rd++;
            `uvm_info("SB_AR", $sformatf(
                "CH%0d AR cmd-link fetch @0x%0h (loai khoi data-path)", ch, t.araddr), UVM_HIGH)
            return;
        end

        // (7) khong duoc co AR khi config-error hoac chua enable
        if (ctx[ch].state == CH_ST_DISABLED)
            `uvm_warning("SB_ORDER",
                $sformatf("CH%0d: thay AR@0x%0h khi channel DISABLED", ch, t.araddr))
        if (ctx[ch].exp_rd.size() == 0) begin
            `uvm_error("SB_AR", $sformatf(
                "CH%0d: AR thua khong co du doan : addr=0x%0h len=%0d size=%0d",
                ch, t.araddr, t.arlen, size))
            err_addr_mismatch++;
        end
        else begin
            exp = ctx[ch].exp_rd.pop_front();
            if (exp.addr !== t.araddr || exp.beats != beats || exp.size != size) begin
                `uvm_error("SB_AR", $sformatf(
                    "CH%0d AR mismatch\n  exp %s\n  act addr=0x%0h len=%0d size=%0d burst=%0d",
                    ch, exp.convert2string(), t.araddr, t.arlen, size, burst))
                err_addr_mismatch++;
            end
            else `uvm_info("SB_AR",
                $sformatf("CH%0d AR OK %s", ch, exp.convert2string()), UVM_HIGH)
        end
        // outstanding de dat R data
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
        size = ob.size; bpb = (1<<size);
        nbeats = t.rdata.size();               // so beat thuc su co data
        a = ob.addr;
        for (int i=0; i<nbeats; i++) begin
            bit [DATA_WIDTH-1:0] beat = t.rdata[i];
            for (int b=0; b<bpb; b++) begin
                ctx[ch].src_stream.push_back(beat[8*b +: 8]);
                ctx[ch].bytes_read++;
            end
            if (!ob.fixed) a += bpb;
        end
        // sau khi co them byte nguon, nap byte dich ky vong vao ref-memory
        push_expected_dest(ch);
        peek_check_counters(ch);           // (6) peek live counter tai bien R
    endtask

    // ap bien doi command len src_stream -> set_expected tai dia chi dich
    function void push_expected_dest(int ch);
        dma_golden_intent gi = ctx[ch].intent;
        if (gi == null) return;
        // COPY 1D (duong datapath duoc RTL model): byte dich = byte nguon theo
        // thu tu; dia chi dich tang theo des_xaddrinc*unit (increment=0 => FIXED)
        while (ctx[ch].src_stream.size() > 0) begin
            bit [7:0] d = ctx[ch].src_stream.pop_front();
            refmem.set_expected(ctx[ch].des_fill_ptr, d);
            // buoc dia chi dich: dung 1 byte (contiguous) cho copy don gian
            ctx[ch].des_fill_ptr += 1;
        end
    endfunction

    //=========================================================================
    // (4) COMPARATOR write-address : so AW thuc te voi burst du doan
    //=========================================================================
    task process_aw(axi5_slave_tx t, int port);
        int ch = ch_from_axi(t, 1'b0);
        int size = int'(t.awsize);
        int beats = int'(t.awlen) + 1;
        bit [1:0] burst = t.awburst;
        dma_axi_burst exp, obs;
        if (gi_fill_only(ch)) begin
            // FILL: khong doc nguon nhung van du doan write; van so binh thuong
        end
        if (ctx[ch].exp_wr.size() == 0) begin
            `uvm_error("SB_AW", $sformatf(
                "CH%0d: AW thua khong co du doan : addr=0x%0h len=%0d size=%0d",
                ch, t.awaddr, t.awlen, size))
            err_addr_mismatch++;
        end
        else begin
            exp = ctx[ch].exp_wr.pop_front();
            if (exp.addr !== t.awaddr || exp.beats != beats || exp.size != size) begin
                `uvm_error("SB_AW", $sformatf(
                    "CH%0d AW mismatch\n  exp %s\n  act addr=0x%0h len=%0d size=%0d",
                    ch, exp.convert2string(), t.awaddr, t.awlen, size))
                err_addr_mismatch++;
            end
            else `uvm_info("SB_AW",
                $sformatf("CH%0d AW OK %s", ch, exp.convert2string()), UVM_HIGH)
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
        for (int i=0; i<nbeats; i++) begin
            bit [DATA_WIDTH-1:0]     beat  = t.wdata[i];
            bit [(DATA_WIDTH/8)-1:0] wstrb = (i < t.wstrb.size()) ? t.wstrb[i] : '1;
            if (gi_fill_only(ch)) begin
                // FILL: byte dich ky vong = FILLVAL (theo lane) - dat truc tiep
                for (int b=0; b<bpb; b++)
                    refmem.set_expected(a+b, ctx[ch].intent.fillval[8*(b%4) +: 8]);
            end
            for (int b=0; b<bpb; b++) begin
                if (wstrb[b]) begin           // xu ly unaligned dau/cuoi qua wstrb
                    refmem.set_actual(a+b, beat[8*b +: 8]);
                    ctx[ch].bytes_written++;
                end
            end
            if (!ob.fixed) a += bpb;
        end
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
    // (6) RECONCILE READBACK : vai tro moi = FRONTDOOR<->BACKDOOR consistency.
    //   * prdata (doc APB, frontdoor) PHAI khop peek (backdoor) cung thoi diem
    //   * RO-khi-enabled : config reg khong duoc doi so voi snapshot activation
    //   * STATUS/ERRINFO : bit ket thuc/loi phai khop dieu kien quan sat tren bus
    // (Live counter da duoc peek chu dong o bien AR/R/W -> khong lam lai o day.)
    //=========================================================================
    task reconcile_readback(int ch, bit [7:0] off, bit [31:0] rd);
        bit ok; bit [31:0] bd;
        // 1) consistency frontdoor vs backdoor tai cung thoi diem doc
        ral_peek(ch, off, ok, bd);
        if (ok && rd !== bd)
            `uvm_error("SB_FDBD", $sformatf(
              "CH%0d off=0x%02h : frontdoor prdata=0x%08h != backdoor peek=0x%08h",
              ch, off, rd, bd))
        // 2) kiem ngu nghia theo tung thanh ghi
        case (off)
            CH_STATUS:  check_status(ch, rd);
            CH_ERRINFO: check_errinfo(ch, rd);
            CH_SRCADDR, CH_DESADDR, CH_XSIZE: ; // live-counter: da peek o bien bus
            CH_GPOREAD0: ;                        // doi chieu qua gpo_ch (status agent)
            default:
                // RO-khi-enabled : config phai giu = snapshot chot luc activation
                if (ctx[ch].state == CH_ST_ENABLED &&
                    ctx[ch].cfg_snapshot.exists(off) && rd !== ctx[ch].cfg_snapshot[off])
                    `uvm_warning("SB_ROLOCK", $sformatf(
                      "CH%0d config off=0x%02h doi khi ENABLED : snapshot=0x%08h act=0x%08h",
                      ch, off, ctx[ch].cfg_snapshot[off], rd))
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
            ctx[ch].bytes_written < ctx[ch].exp_total_bytes)
            mism_status($sformatf(
              "CH%0d STAT_DONE nhung moi ghi %0d/%0d byte",
              ch, ctx[ch].bytes_written, ctx[ch].exp_total_bytes));
        // ERR: phai co loi thuc te (bus resp / stream / trigger) quan sat
        if (stat_err && !(ctx[ch].seen_rd_resp_err || ctx[ch].seen_wr_resp_err))
            mism_status($sformatf("CH%0d STAT_ERR nhung khong thay loi tren bus", ch));
        if (stat_done) begin ctx[ch].state = CH_ST_DONE; check_done_counters(ch); end
        if (stat_err)  ctx[ch].state = CH_ST_ERROR;
        if (stat_stop) ctx[ch].state = CH_ST_STOPPED;
        if (stat_paus) ctx[ch].state = CH_ST_PAUSED;
    endtask

    // DONE-exact : srcaddr = start + tong byte (INCR) / giu (FIXED); xsize = 0
    task check_done_counters(int ch);
        dma_golden_intent gi = ctx[ch].intent;
        bit ok_s, ok_x; bit [31:0] s, x;
        if (gi == null) return;
        ral_peek(ch, CH_SRCADDR, ok_s, s);
        ral_peek(ch, CH_XSIZE,   ok_x, x);
        if (ok_s && !gi.fill_en) begin
            longint expa = gi.srcaddr + (gi.src_xaddrinc==0 ? 0 : gi.total_src_bytes());
            if (s !== expa[31:0])
                mism_status($sformatf("CH%0d DONE SRCADDR peek=0x%0h exp=0x%0h",ch,s,expa));
        end
        if (ok_x && x[15:0] != 0)
            mism_status($sformatf("CH%0d DONE nhung SRCXSIZE=%0d != 0", ch, x[15:0]));
    endtask

    // ERRINFO bit phai khop loai loi thuc te
    function void check_errinfo(int ch, bit [31:0] e);
        if (e[EI_AXIRDRESPERR] && !ctx[ch].seen_rd_resp_err)
            mism_status($sformatf("CH%0d ERRINFO.AXIRDRESPERR nhung R khong loi",ch));
        if (e[EI_AXIWRRESPERR] && !ctx[ch].seen_wr_resp_err)
            mism_status($sformatf("CH%0d ERRINFO.AXIWRRESPERR nhung B khong loi",ch));
    endfunction

    function void mism_status(string m);
        `uvm_error("SB_STATUS", m) err_status_mismatch++;
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
            if (en && !ctx[ch].prev_enabled)
                do_activation_snapshot(ch);       // settle 1 clock roi peek config
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
    task process_boot(boot_seq_item t);
        if (t.boot_en)
            `uvm_info("SB_BOOT", $sformatf(
              "autoboot Ch0 tu descriptor @0x%0h - se decode command-link qua AR",
              {t.boot_addr,2'b00}), UVM_MEDIUM)
        // fetch descriptor se xuat hien tren AR (arcmdlink=1) -> decode o process_ar
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
        // AR/AW du doan chua tieu thu het = giao dich THIEU
        foreach (ctx[ch]) begin
            if (ch >= num_channels) continue;
            if (ctx[ch].exp_rd.size() > 0)
                `uvm_error("SB_EOT", $sformatf(
                  "CH%0d con %0d read-burst du doan CHUA thay tren bus",
                  ch, ctx[ch].exp_rd.size()))
            if (ctx[ch].exp_wr.size() > 0)
                `uvm_error("SB_EOT", $sformatf(
                  "CH%0d con %0d write-burst du doan CHUA thay tren bus",
                  ch, ctx[ch].exp_wr.size()))
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
