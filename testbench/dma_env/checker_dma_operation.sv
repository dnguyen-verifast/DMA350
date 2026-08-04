//=============================================================================
// checker_dma_operation.sv
//-----------------------------------------------------------------------------
// Hai nhiem vu:
//
// (1) CHECK FLOW TRIGGER (TRM 5.4.1 command-mode trigger)
//     Channel duoc cau hinh cho trigger ngoai (USESRCTRIGIN + TYPE=HW) thi
//     KHONG DUOC phat AR du lieu truoc khi handshake trigger-in hoan tat.
//     Neu thay AR du lieu som => DMAC tu chay ma khong cho trigger => sai flow.
//
// (2) FSM VONG DOI LENH + PHAT INTENT (moi)
//     Bam theo mot channel qua 4 trang thai DISABLE -> ENABLE -> DONE ->
//     (FETCH) va tai MOI diem lenh bat dau mot vong moi thi goi
//     dma350_predict_intent.emit_intent() de chot config, roi BROADCAST qua
//     intent_ap. Day la duong DUY NHAT dua intent len scoreboard - predictor
//     khong con tu phat theo canh len ch_enabled nua.
//
//     Vi sao lam o day: intent phai chot lai cho TUNG vong (autorestart, link
//     descriptor moi), ma chi FSM nay moi biet ranh gioi giua cac vong.
//
//-----------------------------------------------------------------------------
// LUU Y QUAN TRONG ve INDEX:
//
//   trig_in_* duoc danh chi so theo CONG <TI> (0..NUM_TRIGGER_IN-1), KHONG
//   phai theo channel. Mot channel chon cong nao la do CH_SRCTRIGINCFG.SEL
//   quyet dinh. Vi vay o day dung:
//        sel = gi[ch].srctrig_sel;   trig_in_req[sel] && trig_in_ack[sel]
//   chu khong phai trig_in_req[ch]. Voi NUM_CHANNELS=8 va NUM_TRIGGER_IN=4,
//   index bang channel se ra ngoai dai hoac soi nham cong.
//
//   Tuong tu, channel cua mot AR lay tu ARCHID (khi CHIDVALID) hoac ARID,
//   giong ch_from_axi() cua scoreboard - khong gia dinh ARID == channel.
//=============================================================================
`ifndef CHECKER_DMA_OPERATION_SV
`define CHECKER_DMA_OPERATION_SV

// Doi ten tu ST_* -> CMD_ST_* : ST_* de dung nham voi cac localparam bit STATUS
// (ST_STAT_DONE, ST_STAT_ERR...) khai bao ngay tren trong cung package.
typedef enum {
    CMD_ST_DISABLE,   // chua co lenh nao chay - dang cho ENABLECMD / autoboot
    CMD_ST_ENABLE,    // lenh dang chay - dem du lieu cho den khi xong
    CMD_ST_DONE,      // mot vong xong - quyet dinh restart / link / ket thuc
    CMD_ST_FETCH      // dang doc command descriptor qua command-link
} cmd_state_e;
parameter int NUM_CHANNELS    = 8;
class checker_dma_operation extends uvm_component;
    `uvm_component_utils(checker_dma_operation)

    virtual dma_if vif;

    uvm_event ch_enabled_event [NUM_CHANNELS];
    bit       ch_en_q          [NUM_CHANNELS];

    // intent tu predictor (neu co nguon ngoai muon nap vao) - van giu de
    // check_flow() dung duoc ngay ca khi FSM lenh chua chay.
    uvm_analysis_imp #(dma_golden_intent, checker_dma_operation) gi_imp;

    // DUONG CHINH dua intent len scoreboard
    uvm_analysis_port #(dma_golden_intent) intent_ap;

    // moc phu cho coverage / debug: 1 xung khi lenh bat dau va khi lenh xong
    uvm_analysis_port #(bit) start_cmd_port;
    uvm_analysis_port #(bit) done_cmd_port;

    // Handle predictor. GAN TU env.connect_phase - KHONG tu create o day.
    // (Truoc day file nay goi type_id::create(...) khong parent trong
    //  build_phase: component sinh ra nam ngoai cay UVM, build/connect cua no
    //  khong chay dung thu tu nen m_ral luon null -> moi peek tra ve 0.)
    dma350_predict_intent dma350_predict_intent_h;

    // intent hien hanh theo channel
    dma_golden_intent gi [int];

    // da thay handshake trigger-in cho channel nay ke tu luc activate chua
    bit  trig_seen [int];

    // Da thay SW ghi CH_CMD.DISABLECMD cho channel nay chua.
    //
    // KHONG doc duoc tu cur_intent_dma.disablecmd: intent la SNAPSHOT chup luc
    // lenh bat dau, ma DISABLECMD thi SW ghi SAU do (giua chung transfer, hoac
    // ngay truoc khi vong autorestart/link ke tiep khoi dong) -> snapshot luon
    // bang 0. Phai soi truc tiep tren APB.
    bit  disable_req [int];

    int  num_channels    = 8;
    int  num_trigger_in  = 4;
    int  num_trigger_out = 4;    // trig_out_* danh chi so RIENG voi trig_in_*
    int  strb_width      = 4;    // DATA_WIDTH/8 cua dma_if (tb_top: 32/8)

    // Channel ma FSM lenh dang bam. Duong APB tu cap nhat theo PADDR[10:8];
    // duong autoboot luon la Ch0 (TRM 4.9.1).
    int  enable_chanel          = 0;

    bit [DATA_WIDTH-1:0] cmd_description [$];

    // So chu ky toi da cho MOT vong lenh truoc khi ket luan DUT TREO. 0 = tat.
    int  cmd_timeout     = 500000;
    // So chu ky cho thanh ghi settle sau khi descriptor duoc nap / sau
    // ENABLECMD, truoc khi peek. Command-link can vai chu ky.
    int  settle_cycles   = 0;
    // Chan vong lap FSM khi CMDRESTARTEN=1 ma CMDRESTARTCNT=0 (restart vo han).
    int  max_restart     = 1024;

    int  n_err           = 0;
    int  n_checked       = 0;
    int  n_cmd           = 0;
    int  n_timeout       = 0;

    cmd_state_e       state = CMD_ST_DISABLE;
    dma_golden_intent cur_intent_dma;             // intent cua vong lenh dang chay
    int               autorestart_cnt = 0;

    function new(string name = "checker_dma_operation", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        gi_imp         = new("gi_imp",         this);
        intent_ap      = new("intent_ap",      this);   // TRUOC DAY THIEU -> null deref
        start_cmd_port = new("start_cmd_port", this);
        done_cmd_port  = new("done_cmd_port",  this);

        if (!uvm_config_db#(virtual dma_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "khong lay duoc virtual dma_if 'vif' tu config_db")
        void'(uvm_config_db#(int)::get(this, "", "num_channels",   num_channels));
        void'(uvm_config_db#(int)::get(this, "", "num_trigger_in",  num_trigger_in));
        void'(uvm_config_db#(int)::get(this, "", "num_trigger_out", num_trigger_out));
        void'(uvm_config_db#(int)::get(this, "", "strb_width",     strb_width));
        void'(uvm_config_db#(int)::get(this, "", "cmd_timeout",    cmd_timeout));
        void'(uvm_config_db#(int)::get(this, "", "settle_cycles",  settle_cycles));
        void'(uvm_config_db#(int)::get(this, "", "enable_chanel",         enable_chanel));

        // create event dectect chanel enable/ disable
        foreach(ch_enabled_event[i]) begin
            ch_enabled_event[i] = uvm_event_pool::get_global(%sformats("ch_enabled_event[%0d]",i));
        end

    //    dma350_predict_intent_h = dma350_predict_intent::type_id::create("dma350_predict_intent_h");
    endfunction

    // Chay sau connect_phase cua env -> luc nay handle predictor phai co.
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        if (dma350_predict_intent_h == null)
            `uvm_fatal("CMDTRIG",
              "dma350_predict_intent_h = null : FSM lenh khong chot duoc intent. Gan checker_dma_operation_h.dma350_predict_intent_h trong dma350_env.connect_phase.")
    endfunction

    //-------------------------------------------------------------------------
    // Nguon intent ngoai (neu co) -> luu lai. Khong con la duong chinh.
    //-------------------------------------------------------------------------
    virtual function void write(dma_golden_intent t);
        if (t == null) return;
        if (t.valid) load_intent(t);
        else         drop_intent(t.ch_id);
    endfunction

    //=========================================================================
    // RUN PHASE
    //-------------------------------------------------------------------------
    // LOI TREO CU: chk_cmd_state() chua `forever` NHUNG lai duoc goi TRONG
    // vong `forever` cua run_phase. Lan goi dau tien khong bao gio tra ve ->
    // sample_triggers()/check_flow() chi chay dung 1 chu ky roi im lang ca test,
    // va toan bo check trigger thanh vo dung.
    //
    // Sua: tach thanh cac process SONG SONG, va boc trong mot vong doi RESET.
    // Khi resetn xuong: giet het process, xoa trang thai, cho reset nha ra roi
    // dung day lai tu CMD_ST_DISABLE. Nho vay reset giua chung lenh khong lam
    // FSM ket cung o mot @(...iff...) khong bao gio thoa.
    //=========================================================================
    task run_phase(uvm_phase phase);
        forever begin
            // (1) cho het reset
            if (vif.resetn !== 1'b1) @(posedge vif.resetn);
            do_reset_cleanup();

            // (2) chay cac process, dua tay canh reset vao cung fork
            fork
                sample_loop();
                cmd_fsm_loop();
                wait_chanel_disable();
                begin
                    @(negedge vif.resetn);
                    `uvm_info("CMDTRIG",
                      "resetn xuong : huy FSM lenh + xoa intent, doi reset nha", UVM_MEDIUM)
                end
            join_any
            disable fork;   // giet 2 process con lai (chi con cua process nay)
        end
    endtask

    // Xoa sach trang thai. Bao scoreboard bo moi intent cu: sau reset thanh ghi
    // ve gia tri reset, giu intent cu se sinh du doan burst hoan toan sai.
    function void do_reset_cleanup();
        int keys [$];
        // Gom key TRUOC roi moi invalidate: invalidate() goi gi.delete(ch), ma
        // xoa phan tu ngay trong foreach cua chinh mang ket hop do la hanh vi
        // khong xac dinh trong SV.
        foreach(ch_en_q[h]) ch_en_q[h] = 0;
        foreach (gi[c]) keys.push_back(c);
        foreach (keys[i]) invalidate(keys[i]);
        gi.delete();
        trig_seen.delete();
        disable_req.delete();
        cur_intent_dma          = null;
        state        = CMD_ST_DISABLE;
        autorestart_cnt = 0;
        dma350_predict_intent_h.reset_mirror();   // handle luon hop le, xem capture_intent
    endfunction

    task wait_chanel_disable();
        forever begin
             @(vif.mon_cb);
            foreach(ch_enabled_event[ch])  begin
                if(ch_en_q[ch] && !vif.ch_enabled[ch]) begin
                    ch_enabled_event[ch].trigger();
                    `uvm_info("CH_TRIG_DISABLE","Release trigger for terminate test", UVM_MEDIUM)
                end
                ch_en_q[ch] = vif.ch_enabled[ch];
            end
        end
    endtask

    //=========================================================================
    // PROCESS 1 : lay mau moi chu ky cho check flow trigger
    //=========================================================================
    task sample_loop();
        forever begin
            @(vif.mon_cb);
            sample_triggers();
            sample_disable_cmd();
            check_flow();
        end
    endtask

    //-------------------------------------------------------------------------
    // Soi SW ghi CH_CMD.DISABLECMD cho MOI channel, lien tuc, khong phu thuoc
    // FSM dang o state nao.
    //
    // Vi sao lay mau o day chu khong dat nhanh fork trong tung state: xung ghi
    // APB chi ton tai MOT chu ky. State nao khong co nhanh soi thi xung roi vao
    // do la MAT LUON - vd SW huy dung luc DMAC dang fetch descriptor, sang
    // ST_ENABLE khong con gi de bat nua roi ngoi den het cmd_timeout.
    //
    // Co la DINH (set roi giu), chi xoa khi mot chuoi lenh MOI bat dau
    // (st_disable). Nho vay khong so lech pha: FSM doc cham mot chu ky so voi
    // sample_loop cung khong sao, va thu tu chay giua hai process khong con
    // anh huong gi.
    //-------------------------------------------------------------------------
    function void sample_disable_cmd();
        int ch;
        if (!(vif.mon_cb.psel && vif.mon_cb.penable &&
              vif.mon_cb.pwrite && vif.mon_cb.pready)) return;
        if (!vif.mon_cb.paddr[12])                     return;   // ngoai vung DMACH
        if (vif.mon_cb.paddr[7:0] != CH_CMD)           return;
        if (!vif.mon_cb.pwdata[CMD_DISABLECMD])        return;
        ch = int'(vif.mon_cb.paddr[10:8]);
        if (ch >= num_channels)                        return;
        disable_req[ch] = 1;
        `uvm_info("CMDTRIG", $sformatf(
          "CH%0d thay SW ghi DISABLECMD", ch), UVM_HIGH)
    endfunction

    //=========================================================================
    // PROCESS 2 : FSM vong doi lenh
    //=========================================================================
    task cmd_fsm_loop();
        state = CMD_ST_DISABLE;
        forever cmd_fsm_step();
    endtask

    task cmd_fsm_step();
        case (state)
            CMD_ST_DISABLE: st_disable();
            CMD_ST_ENABLE : st_enable();
            CMD_ST_DONE   : st_done();
            CMD_ST_FETCH  : st_fetch();
            default       : state = CMD_ST_DISABLE;
        endcase
    endtask

    //-------------------------------------------------------------------------
    // CMD_ST_DISABLE : cho lenh khoi dong.
    //
    // Hai duong vao chay SONG SONG (truoc day dung if/else theo boot_en, nen
    // test co boot_en=1 nhung van dung APB de nap lenh tiep theo se ket cung):
    //   * autoboot : boot_en=1 -> Ch0 tu doc command descriptor (AR arcmdlink)
    //   * APB      : ghi CH_CMD.ENABLECMD cua mot channel bat ky
    //
    // KHONG dat watchdog o day: cho testcase phat lenh la thoi gian hop le va
    // khong gioi han; het objection thi UVM tu ket thuc.
    //-------------------------------------------------------------------------
    task st_disable();
        int start_ch = enable_chanel;
        bit via_boot = 0;
        fork
            begin
                wait_boot_fetch();
                start_ch = 0;                // autoboot luon Ch0 (TRM 4.9.1)
                via_boot = 1;
            end
            begin
                wait_enablecmd_apb(start_ch);
                via_boot = 0;
            end
        join_any
        disable fork;

        enable_chanel = start_ch;
        // MOT CHUOI LENH MOI bat dau (ENABLECMD moi / autoboot) => DISABLECMD cu
        // het hieu luc. Day la noi DUY NHAT duoc xoa co.
        //
        // Truoc day xoa trong capture_intent(), nhung capture_intent con duoc
        // goi tu AUTORESTART va COMMAND-LINK - hai truong hop do la lenh CU chay
        // tiep, mot DISABLECMD dang treo PHAI van con hieu luc de st_done() cat
        // chuoi. Xoa o day thi khong dung nham nua.
        disable_req[start_ch] = 0;
        settle();
        // Autoboot doc descriptor qua AXI -> giai ma tu cmd_description mà
        // wait_boot_fetch() vua gom. Duong APB thi thanh ghi da dung san,
        // peek la chinh xac.
        capture_intent(enable_chanel, via_boot ? INTENT_SRC_DESC : INTENT_SRC_APB);
        state = CMD_ST_ENABLE;
    endtask

    // autoboot : doi boot_en, roi doi lan doc command-link DAU TIEN xong.
    // Descriptor duoc nap vao thanh ghi sau RLAST -> peek phai sau do.
    task wait_boot_fetch();
        if (vif.mon_cb.boot_en !== 1'b1) @(vif.mon_cb iff vif.mon_cb.boot_en);
        wait_cmdlink_read_done();
    endtask

    // Doc CH_CMD (offset 0x00) trong vung DMACH (PADDR[12]=1), bit ENABLECMD.
    // Dung mon_cb chu khong doc thang vif.paddr/pwdata (race voi RTL), va co
    // kiem PSEL/PENABLE/PREADY chu khong chi PREADY|PWRITE nhu ban cu.
    task wait_enablecmd_apb(output int ch);
        @(vif.mon_cb iff (vif.mon_cb.psel   && vif.mon_cb.penable &&
                          vif.mon_cb.pwrite && vif.mon_cb.pready  &&
                          vif.mon_cb.paddr[12]                    &&
                          (vif.mon_cb.paddr[7:0] == CH_CMD)       &&
                          vif.mon_cb.pwdata[CMD_ENABLECMD]));
        ch = int'(vif.mon_cb.paddr[10:8]);
        if (ch >= num_channels) ch = 0;
    endtask

    //-------------------------------------------------------------------------
    // CMD_ST_ENABLE : lenh dang chay, doi dieu kien ket thuc.
    //
    // Uu tien dieu kien (giong ban cu, da sua loi):
    //   1) USETRIGOUT     -> soi handshake trig_out roi ha req/ack
    //   2) INTREN.DONE    -> soi ngat channel
    //   3) stream OUT     -> dem byte tren AXI-Stream
    //   4) mac dinh       -> dem byte tren W-channel M0 + doi het outstanding B
    //
    // Ba loi cu da sua:
    //   * nhanh stream KHONG co `break` sau khi dat du byte -> `forever` chay
    //     mai, FSM khong bao gio roi ENABLE => TREO.
    //   * nhanh stream dem $countones(wstrb_m0) (AXI) thay vi str_out_tstrb.
    //   * cong thuc byte nhan des_transize thay vi DICH TRAI (TRANSIZE la log2
    //     byte/item), va doc bien tran `des_transize` khong khai bao.
    //-------------------------------------------------------------------------
    task st_enable();
        longint exp_bytes;
        bit     err      = 0;
        bit     time_out = 0;
        bit     disabled = 0;

        if (cur_intent_dma == null) begin
            `uvm_error("CMDTRIG", "vao CMD_ST_ENABLE ma khong co intent - ve DISABLE")
            state = CMD_ST_DISABLE;
            return;
        end

        exp_bytes = exp_des_bytes(cur_intent_dma);  // count a entire expect byte the destination received
        start_cmd_port.write(1'b1);
        `uvm_info("CMDTRIG", $sformatf(
          "CH%0d lenh CHAY : du kien %0d byte ghi (des_xsize=%0d desysize=%0d transize=%0d)",
          cur_intent_dma.ch_id, exp_bytes, cur_intent_dma.des_xsize, cur_intent_dma.desysize, cur_intent_dma.des_transize), UVM_HIGH)

        fork
            begin
                if (cur_intent_dma.use_trigout)                   wait_trigout_done();
                else if (cur_intent_dma.intren_done && cur_intent_dma.donetype != 3'b000)
                                                       wait_irq_done();
                else if (cur_intent_dma.usestream_out)            wait_stream_bytes(exp_bytes);
                else                                   wait_axi_bytes(exp_bytes);
            end
            begin @(vif.mon_cb iff vif.mon_cb.ch_err[cur_intent_dma.ch_id]);     err = 1; end
            begin @(vif.mon_cb iff vif.mon_cb.ch_stopped[cur_intent_dma.ch_id]); err = 1; end
            // SW huy lenh giua chung. Nhanh nay KHONG de xet, chi de THOAT: bo
            // dem byte se khong bao gio du nua nen neu khong thoat, FSM ngoi
            // den het cmd_timeout roi bao "TREO" sai trong khi DUT huy dung
            // theo lenh cua SW. Viec xet nam o st_done().
            begin wait_disable_flag(cur_intent_dma.ch_id);            disabled = 1; end
            begin wait_timeout();                                     time_out = 1; end
        join_any
        disable fork;

        done_cmd_port.write(1'b1);

        // DISABLECMD : chi THOAT vong doi roi di tiep sang DONE - KHONG tu ket
        // thuc tai cho. Viec XET co nam tap trung o st_done() vi do la noi duy
        // nhat quyet dinh "co chay vong tiep khong" (autorestart / command-link).
        // Nhay thang ve DISABLE tu day se lam gate trong st_done() thanh code
        // chet, va sau nay them duong vao DONE nao khac thi lai quen kiem.
        // (Co da do sample_disable_cmd() ghim, o day khong set lai.)
        if (disabled) begin
            `uvm_info("CMDTRIG", $sformatf(
              "CH%0d DISABLECMD khi lenh dang chay - dung dem byte, de st_done xu ly",
              cur_intent_dma.ch_id), UVM_MEDIUM)
            state = CMD_ST_DONE;
        end
        else if (time_out) begin
            n_timeout++;
            n_err++;
            `uvm_error("CMDTRIG", $sformatf(
              "CH%0d TREO: qua %0d chu ky ma lenh chua ket thuc (du kien %0d byte). FSM tu ve DISABLE de test khong dung hinh.",
              cur_intent_dma.ch_id, cmd_timeout, exp_bytes))
            invalidate(cur_intent_dma.ch_id);
            cur_intent_dma   = null;
            state = CMD_ST_DISABLE;
        end
        else if (err) begin
            `uvm_info("CMDTRIG", $sformatf(
              "CH%0d ket thuc bat thuong (ch_err/ch_stopped) - khong restart/link",
              cur_intent_dma.ch_id), UVM_MEDIUM)
            invalidate(cur_intent_dma.ch_id);
            cur_intent_dma   = null;
            state = CMD_ST_DISABLE;
        end
        else state = CMD_ST_DONE;
    endtask

    // trig-out: doi handshake roi doi CA HAI phia ha (4-phase) truoc khi coi xong
    //
    // CAN NHAC: dieu nay chi dung khi TRIGOUTCFG.TYPE bao trig-out phat MOT lan
    // o cuoi lenh. Neu cau hinh cho phat theo TUNG BLOCK thi lan handshake dau
    // tien se bi hieu nham la "lenh xong" -> FSM sang DONE som va chot intent
    // thua. Testcase nao dung trig-out kieu block nen tat nhanh nay (dat
    // cmd_timeout / doi thu tu uu tien trong st_enable).
    task wait_trigout_done();
        int sel = int'(cur_intent_dma.trigout_sel);
        if (sel >= num_trigger_out) begin
            `uvm_error("CMDTRIG", $sformatf(
              "CH%0d TRIGOUTCFG.SEL=%0d vuot so cong (%0d) - khong soi duoc trig-out",
              cur_intent_dma.ch_id, sel, num_trigger_out))
            wait_timeout();       // de watchdog xu ly thay vi treo vinh vien
            return;
        end
        @(vif.mon_cb iff (vif.mon_cb.trig_out_req[sel] && vif.mon_cb.trig_out_ack[sel]));
        @(vif.mon_cb iff !vif.mon_cb.trig_out_req[sel]);
        @(vif.mon_cb iff !vif.mon_cb.trig_out_ack[sel]);
    endtask

    task wait_irq_done();
        @(vif.mon_cb iff vif.mon_cb.irq_channel[cur_intent_dma.ch_id]);
    endtask

    // Dem byte tren W-channel + doi het outstanding write (B da ve du).
    //
    // Dem CA M0 LAN M1: dich cua mot lenh nam tren bus nao la do address-map
    // quyet dinh, ban cu chi dem M0 nen moi transfer di qua M1 se khong bao gio
    // dat du byte -> treo den tan watchdog. FSM chi bam MOT channel tai mot
    // thoi diem nen cong don hai bus khong bi lan.
    //
    // outstanding duoc kep >= 0 de mot B "la" (vd cua command-link) khong day
    // counter xuong am roi khien dieu kien ket thuc thoa som.
    // !!!!(need check)  can be wrong with multi_chanel operate simultanseously
    task wait_axi_bytes(longint exp_bytes);
        longint wr_bytes    = 0;
        int     outstanding = 0;
        forever begin
            @(vif.mon_cb);
            if (vif.mon_cb.awvalid_m0 && vif.mon_cb.awready_m0) outstanding++;
            if (vif.mon_cb.awvalid_m1 && vif.mon_cb.awready_m1) outstanding++;
            if (vif.mon_cb.wvalid_m0  && vif.mon_cb.wready_m0)
                wr_bytes += $countones(vif.mon_cb.wstrb_m0);
            if (vif.mon_cb.wvalid_m1  && vif.mon_cb.wready_m1)
                wr_bytes += $countones(vif.mon_cb.wstrb_m1);
            if (vif.mon_cb.bvalid_m0  && vif.mon_cb.bready_m0 && outstanding > 0)
                outstanding--;
            if (vif.mon_cb.bvalid_m1  && vif.mon_cb.bready_m1 && outstanding > 0)
                outstanding--;
            if (wr_bytes >= exp_bytes && outstanding == 0) break;
        end
    endtask

    // Dem byte tren AXI-Stream OUT cua channel. tstrb la vector FLATTEN theo
    // channel -> phai cat dung lat [ch*STRB +: STRB].
    task wait_stream_bytes(longint exp_bytes);
        longint wr_bytes = 0;
        int     ch = cur_intent_dma.ch_id;
        forever begin
            @(vif.mon_cb);
            if (vif.mon_cb.str_out_tvalid[ch] && vif.mon_cb.str_out_tready[ch])
                wr_bytes += $countones(strb_slice(vif.mon_cb.str_out_tstrb, ch));
            if (wr_bytes >= exp_bytes) break;   // TRUOC DAY THIEU -> treo
        end
    endtask

    task wait_timeout();
        if (cmd_timeout <= 0) begin
            forever @(vif.mon_cb);              // watchdog tat -> khong bao gio ban
        end
        else repeat (cmd_timeout) @(vif.mon_cb);
    endtask

    //-------------------------------------------------------------------------
    // Doi co DISABLECMD (do sample_disable_cmd() ghim) cua channel dang bam.
    // Kiem TRUOC khi doi clock: co the co da dinh san tu truoc khi vao state
    // (vd SW huy trong luc DMAC dang fetch descriptor) - luc do phai thoat
    // ngay, khong doi them chu ky nao.
    //-------------------------------------------------------------------------
    task wait_disable_flag(int ch);
        forever begin
            if (disable_req.exists(ch) && disable_req[ch]) return;
            @(vif.mon_cb);
        end
    endtask

    //-------------------------------------------------------------------------
    // CMD_ST_DONE : mot vong da xong, di dau tiep?
    //
    // Thu tu uu tien: DISABLECMD > autorestart > command-link (TRM 3.3).
    // DISABLECMD phai dung TRUOC vi no huy CA autorestart LAN command-link -
    // SW ghi DISABLECMD ngay khi vong hien tai sap xong la cach hop le de dung
    // mot chuoi autorestart, neu khong kiem thi FSM van quay tiep va chot ra
    // intent cho nhung vong KHONG BAO GIO CHAY -> scoreboard du doan burst thua
    // roi bao thieu byte o check_phase.
    //
    // Loi cu: doc cur_intent_dma.disablecmd (snapshot CH_CMD chup luc ENABLE
    // nen luon 0 - xem chu thich o khai bao disable_req) va dieu kien restart
    // `cmdrstren || cmdrestrcnt > 0` KHONG BAO GIO GIAM -> vong DONE->ENABLE
    // lap vo han. Nay dung co disable_req + bo dem autorestart_cnt rieng.
    //-------------------------------------------------------------------------
    task st_done();
        int ch = cur_intent_dma.ch_id;
        if (disable_req.exists(ch) && disable_req[ch]) begin
            `uvm_info("CMDTRIG", $sformatf(
              "CH%0d DISABLECMD dang bat - dung chuoi lenh (bo qua autorestart=%0d link=%0b)",
              ch, autorestart_cnt, cur_intent_dma.linkaddren), UVM_MEDIUM)
            invalidate(ch);
            cur_intent_dma  = null;
            autorestart_cnt = 0;
            state = CMD_ST_DISABLE;
        end
        else if (autorestart_cnt > 0) begin
            int left = autorestart_cnt - 1;
            `uvm_info("CMDTRIG", $sformatf(
              "CH%0d autorestart, con %0d lan - chot lai intent", ch, left), UVM_HIGH)
            settle();
            // Autorestart KHONG doc AXI va khong nap thanh ghi moi -> khong co
            // descriptor de giai ma, cung khong duoc peek (thanh ghi da bi vong
            // vua chay tieu thu: SRCADDR chay toi, XSIZE dem lui). Dung lai anh
            // thanh ghi ma predictor dang giu.
            capture_intent(ch, INTENT_SRC_REPEAT);
            // capture_intent nap LAI autorestart_cnt tu CH_AUTOCFG (van la gia tri
            // goc) -> phai ap lai bo dem da giam, khong thi vong DONE->ENABLE
            // lap VO HAN.
            autorestart_cnt = left;
            state = CMD_ST_ENABLE;
        end
        else if (cur_intent_dma.linkaddren) begin
            `uvm_info("CMDTRIG", $sformatf(
              "CH%0d command-link -> doc descriptor @0x%0h", ch, cur_intent_dma.linkaddr), UVM_HIGH)
            state = CMD_ST_FETCH;
        end
        else begin
            `uvm_info("CMDTRIG", $sformatf("CH%0d lenh KET THUC", ch), UVM_HIGH)
            invalidate(ch);
            cur_intent_dma   = null;
            state = CMD_ST_DISABLE;
        end
    endtask

    //-------------------------------------------------------------------------
    // CMD_ST_FETCH : doi command descriptor duoc doc xong.
    //
    // Loi cu: doi B-response (bvalid/bready, bid==0). Descriptor fetch la mot
    // lan DOC (AR co ARCMDLINK=1) chu khong phai ghi - cho B se treo vinh vien.
    //-------------------------------------------------------------------------
    // KHONG kiem DISABLECMD o day: FSM vua di qua gate cua st_done() de vao
    // duoc FETCH, va lan doc descriptor la mot burst AXI DA PHAT - slave buoc
    // phai tra du beat nen no ket thuc binh thuong du channel co bi disable.
    // Neu SW co ghi DISABLECMD dung trong cua so nay thi sample_disable_cmd()
    // da ghim co roi; sang ST_ENABLE nhanh wait_disable_flag() thay co dinh san
    // va thoat ngay -> quay ve st_done() xu ly. Mot noi XET duy nhat.
    task st_fetch();
        int ch       = cur_intent_dma.ch_id;
        bit time_out = 0;
        fork
            wait_cmdlink_read_done();
            begin wait_timeout(); time_out = 1; end
        join_any
        disable fork;

        if (time_out) begin
            n_timeout++;
            n_err++;
            `uvm_error("CMDTRIG", $sformatf(
              "CH%0d TREO o CMD_ST_FETCH: khong thay lan doc command-link nao trong %0d chu ky",
              ch, cmd_timeout))
            invalidate(ch);
            cur_intent_dma   = null;
            state = CMD_ST_DISABLE;
            return;
        end
        settle();
        capture_intent(ch, INTENT_SRC_DESC);
        state = CMD_ST_ENABLE;
    endtask

    //-------------------------------------------------------------------------
    // AR co ARCMDLINK=1 tren M0 hoac M1, roi GOM TUNG BEAT R cho den RLAST.
    //
    // Day la nguon du lieu de chot intent cho boot / command-link: thay vi doi
    // RTL nap descriptor vao thanh ghi roi peek (mat ~33ck, lai khong co moc bao
    // "nap xong" nen peek trung config cua lenh TRUOC), ta doc thang chinh cai
    // descriptor ma DMAC vua nhan. Khong con phu thuoc do tre nao.
    //
    // MOT process, KHONG fork: ban fork/join truoc do co 3 loi -
    //   * nhanh 2 doc on_m1 truoc khi nhanh 1 kip gan  -> luon chay nhanh M0
    //   * push nham bus (on_m1 dung nhung lay rdata_m0)
    //   * dangling-else: "if (A) if (B) X; else if (C) Y;" thi else thuoc if(B),
    //     nen khi A=0 KHONG beat nao duoc gom
    //-------------------------------------------------------------------------
    task wait_cmdlink_read_done();
        bit on_m1;
        cmd_description.delete();          // vut descriptor cua lan fetch truoc

        @(vif.mon_cb iff ((vif.mon_cb.arvalid_m0 && vif.mon_cb.arready_m0 && vif.mon_cb.arcmdlink_m0) ||
                          (vif.mon_cb.arvalid_m1 && vif.mon_cb.arready_m1 && vif.mon_cb.arcmdlink_m1)));
        on_m1 = !(vif.mon_cb.arvalid_m0 && vif.mon_cb.arready_m0 && vif.mon_cb.arcmdlink_m0);

        forever begin
            @(vif.mon_cb);
            if (on_m1) begin
                if (!(vif.mon_cb.rvalid_m1 && vif.mon_cb.rready_m1)) continue;
                cmd_description.push_back(vif.mon_cb.rdata_m1);
                if (vif.mon_cb.rlast_m1) break;
            end
            else begin
                if (!(vif.mon_cb.rvalid_m0 && vif.mon_cb.rready_m0)) continue;
                cmd_description.push_back(vif.mon_cb.rdata_m0);
                if (vif.mon_cb.rlast_m0) break;
            end
        end

        `uvm_info("CMDTRIG", $sformatf(
          "bat duoc descriptor tren %s: %0d beat, header=0x%08h",
          on_m1 ? "M1" : "M0", cmd_description.size(),
          (cmd_description.size() > 0) ? cmd_description[0] : '0), UVM_HIGH)
    endtask

    //-------------------------------------------------------------------------
    // Cat cac beat da bat duoc thanh chuoi WORD 32-bit dung thu tu.
    // Descriptor DMA-350 la mang tu 32-bit lien tiep; bus rong hon 32 thi moi
    // beat chua nhieu word, tach theo little-endian.
    //-------------------------------------------------------------------------
    function void build_desc_words(output bit [31:0] w [$]);
        int nw = (DATA_WIDTH < 32) ? 1 : (DATA_WIDTH / 32);
        w.delete();
        foreach (cmd_description[i])
            for (int k = 0; k < nw; k++)
                w.push_back(cmd_description[i][k*32 +: 32]);
    endfunction

    task settle();
        repeat (settle_cycles) @(vif.mon_cb);
    endtask

    //=========================================================================
    // CHOT INTENT + BROADCAST
    //=========================================================================
    // dma350_predict_intent_h KHONG can kiem null o day: no do
    // dma350_env.connect_phase gan, va end_of_elaboration_phase ben duoi da
    // uvm_fatal neu van null. Phase chay theo thu tu connect -> end_of_elaboration
    // -> run, ma uvm_fatal ket thuc sim ngay, nen run_phase khong the chay voi
    // handle null.
    //
    // src quyet dinh predictor lay config o dau:
    //   INTENT_SRC_APB    - SW da ghi xong thanh ghi truoc ENABLECMD -> peek
    //   INTENT_SRC_DESC   - boot / command-link -> giai ma descriptor vua bat
    //                       duoc tren kenh R (cmd_description)
    //   INTENT_SRC_REPEAT - autorestart, khong nap gi moi -> dung lai anh cu
    task capture_intent(int ch, intent_src_e src);
        dma_golden_intent t;
        bit [31:0] desc [$];

        if (src == INTENT_SRC_DESC) begin
            build_desc_words(desc);
            if (desc.size() == 0) begin
                `uvm_error("CMDTRIG", $sformatf(
                  "CH%0d chot intent tu descriptor nhung khong bat duoc beat R nao", ch))
                return;
            end
        end

        dma350_predict_intent_h.emit_intent(ch, src, desc, t);
        if (t == null) begin
            `uvm_error("CMDTRIG", $sformatf(
              "CH%0d chot intent that bai (%s)", ch, src.name()))
            return;
        end
        cur_intent_dma = t;
        load_intent(t);
        // CMDRESTARTEN=1 + CMDRESTARTCNT=0 = restart vo han (TRM CH_AUTOCFG).
        // Kep bang max_restart de FSM khong quay vo tan neu DUT khong bao gio
        // ha CMDRESTARTEN.
        if (t.cmdrestrcnt > 0)   autorestart_cnt = int'(t.cmdrestrcnt);
        else if (t.cmdrstren)    autorestart_cnt = max_restart;
        else                     autorestart_cnt = 0;

        n_cmd++;
        intent_ap.write(t);
        `uvm_info("CMDTRIG", $sformatf(
          "CH%0d chot intent (%s): src=0x%0h des=0x%0h desxsize=%0d desysize=%0d restart=%0d link=%0b",
          ch, src.name(), t.srcaddr, t.desaddr, t.des_xsize, t.desysize,
          autorestart_cnt, t.linkaddren), UVM_MEDIUM)
    endtask

    // Nap intent vao bang tra cuu cua check flow trigger
    function void load_intent(dma_golden_intent t);
        gi[t.ch_id]        = t;
        trig_seen[t.ch_id] = 0;              // vong lenh moi: chua thay trigger nao
        if (t.ext_cmd)
            `uvm_info("CMDTRIG", $sformatf(
              "CH%0d vao che do trigger ngoai (cong TI%0d) - bat dau soi flow",
              t.ch_id, t.srctrig_sel), UVM_HIGH)
    endfunction

    function void drop_intent(int ch);
        if (gi.exists(ch)) gi.delete(ch);
        trig_seen[ch] = 0;
    endfunction

    // Bao downstream (scoreboard) intent cua channel het hieu luc
    function void invalidate(int ch);
        dma_golden_intent t = dma_golden_intent::type_id::create("gi_inv");
        t.ch_id = ch;
        t.valid = 0;
        intent_ap.write(t);
        drop_intent(ch);
    endfunction

    //=========================================================================
    // TONG BYTE PHIA DICH cua mot lenh.
    // TRANSIZE la LOG2 so byte/item -> phai DICH TRAI, khong phai nhan.
    // YSIZE chi co nghia khi YTYPE != 0 (transfer 2D).
    //=========================================================================
    function longint exp_des_bytes(dma_golden_intent g);
        int rows  = (g.ytype != 0 && g.desysize > 0) ? g.desysize : 1;
        int items = (g.des_xsize > 0) ? g.des_xsize : 0;
        return longint'(items) * rows * (longint'(1) << g.des_transize);
    endfunction

    // Cat lat STRB cua channel ra khoi vector flatten
    function bit [63:0] strb_slice(bit [255:0] flat, int ch);
        bit [63:0] r = '0;
        for (int b = 0; b < strb_width; b++)
            r[b] = flat[ch*strb_width + b];
        return r;
    endfunction

    //-------------------------------------------------------------------------
    // Ghi nhan handshake trigger-in tren tung CONG, quy ve channel dang dung
    // cong do.
    //-------------------------------------------------------------------------
    function void sample_triggers();
        foreach (gi[ch]) begin
            int sel;
            if (gi[ch] == null || !gi[ch].valid || !gi[ch].ext_cmd) continue;
            sel = int'(gi[ch].srctrig_sel);
            if (sel >= num_trigger_in) continue;         // SEL sai -> bo qua
            if (vif.mon_cb.trig_in_req[sel] && vif.mon_cb.trig_in_ack[sel])
                trig_seen[ch] = 1;
        end
    endfunction

    //-------------------------------------------------------------------------
    // Check chinh: AR du lieu (khong phai command-link fetch) khong duoc xuat
    // hien truoc khi trigger-in cua channel do handshake xong.
    //-------------------------------------------------------------------------
    function void check_flow();
        foreach (gi[ch]) begin
            if (gi[ch] == null || !gi[ch].valid) continue;
            if (!gi[ch].ext_cmd)                 continue;   // chi ap cho trigger ngoai
            if (ch >= num_channels)              continue;
            if (!vif.mon_cb.ch_enabled[ch])      continue;

            // AR du lieu tren M0 / M1 thuoc channel nay?
            if (ar_data_for_ch(ch)) begin
                n_checked++;
                if (!trig_seen[ch]) begin
                    n_err++;
                    `uvm_error("CMDTRIG", $sformatf(
                      "CH%0d: phat AR DU LIEU truoc khi handshake trigger-in (cong TI%0d) hoan tat -> sai flow",
                      ch, gi[ch].srctrig_sel))
                end
            end
        end
    endfunction

    // AR dang handshake, khong phai command-link, va thuoc channel ch
    function bit ar_data_for_ch(int ch);
        bit m0 = vif.mon_cb.arvalid_m0 && vif.mon_cb.arready_m0 &&
                 !vif.mon_cb.arcmdlink_m0 &&
                 (ch_of_ar(vif.mon_cb.archid_m0, vif.mon_cb.archidvalid_m0,
                           vif.mon_cb.arid_m0) == ch);
        bit m1 = vif.mon_cb.arvalid_m1 && vif.mon_cb.arready_m1 &&
                 !vif.mon_cb.arcmdlink_m1 &&
                 (ch_of_ar(vif.mon_cb.archid_m1, vif.mon_cb.archidvalid_m1,
                           vif.mon_cb.arid_m1) == ch);
        return m0 || m1;
    endfunction

    // Channel cua mot AR: uu tien ARCHID khi CHIDVALID, khong thi roi ve ARID
    // (giong ch_from_axi cua scoreboard).
    function int ch_of_ar(bit [7:0] chid, bit chidvalid, bit [3:0] id);
        int c = chidvalid ? int'(chid) : int'(id);
        if (c >= num_channels) c = int'(id);
        if (c >= num_channels) c = 0;
        return c;
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("CMDTRIG", $sformatf(
          "checker_dma_operation: %0d lenh chot intent, %0d AR du lieu duoc soi, %0d vi pham flow, %0d lan TREO (timeout)",
          n_cmd, n_checked, n_err, n_timeout), UVM_LOW)
    endfunction

endclass

`endif // CHECKER_DMA_OPERATION_SV
