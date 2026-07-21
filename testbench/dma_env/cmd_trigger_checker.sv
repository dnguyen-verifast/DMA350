//=============================================================================
// cmd_trigger_checker.sv
//-----------------------------------------------------------------------------
// Kiem tra LUONG KHOI DONG BANG TRIGGER (TRM 5.4.1 command-mode trigger):
//
//   Channel duoc cau hinh cho trigger ngoai (USESRCTRIGIN + TYPE=HW) thi
//   KHONG DUOC phat AR du lieu truoc khi handshake trigger-in hoan tat.
//   Neu thay AR du lieu som => DMAC tu chay ma khong cho trigger => sai flow.
//
// Nhan dma_golden_intent tu dma350_predict_intent (analysis_imp) de biet
// channel nao dang o che do trigger va dung CONG trigger nao.
//
//-----------------------------------------------------------------------------
// LUU Y QUAN TRONG ve INDEX (khac voi ban phac thao ban dau):
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
`ifndef CMD_TRIGGER_CHECKER_SV
`define CMD_TRIGGER_CHECKER_SV

class cmd_trigger_checker extends uvm_component;
    `uvm_component_utils(cmd_trigger_checker)

    virtual dma_if vif;

    // intent tu predictor
    uvm_analysis_imp #(dma_golden_intent, cmd_trigger_checker) gi_imp;

    // intent hien hanh theo channel
    dma_golden_intent gi [int];

    // da thay handshake trigger-in cho channel nay ke tu luc activate chua
    bit  trig_seen [int];

    int  num_channels    = 8;
    int  num_trigger_in  = 4;
    int  n_err           = 0;
    int  n_checked       = 0;

    function new(string name = "cmd_trigger_checker", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        gi_imp = new("gi_imp", this);
        if (!uvm_config_db#(virtual dma_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "khong lay duoc virtual dma_if 'vif' tu config_db")
        void'(uvm_config_db#(int)::get(this, "", "num_channels",   num_channels));
        void'(uvm_config_db#(int)::get(this, "", "num_trigger_in", num_trigger_in));
    endfunction

    //-------------------------------------------------------------------------
    // predictor ban intent xuong -> luu lai
    //-------------------------------------------------------------------------
    virtual function void write(dma_golden_intent t);
        gi[t.ch_id] = t;
        if (t.valid) begin
            trig_seen[t.ch_id] = 0;      // vong lenh moi: chua thay trigger nao
            if (t.ext_cmd)
                `uvm_info("CMDTRIG", $sformatf(
                  "CH%0d vao che do trigger ngoai (cong TI%0d) - bat dau soi flow",
                  t.ch_id, t.srctrig_sel), UVM_HIGH)
        end
    endfunction

    //-------------------------------------------------------------------------
    // Lay mau moi chu ky. Dung mon_cb de sample dong nhat (tranh race voi RTL).
    //-------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        forever begin
            @(vif.mon_cb);
            if (!vif.resetn) begin
                foreach (trig_seen[c]) trig_seen[c] = 0;
                continue;
            end
            sample_triggers();
            check_flow();
        end
    endtask

    //-------------------------------------------------------------------------
    // Ghi nhan handshake trigger-in tren tung CONG, quy ve channel dang dung
    // cong do.
    //-------------------------------------------------------------------------
    function void sample_triggers();
        for (int ch = 0; ch < num_channels; ch++) begin
            int sel;
            if (!gi.exists(ch) || !gi[ch].valid || !gi[ch].ext_cmd) continue;
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
        for (int ch = 0; ch < num_channels; ch++) begin
            if (!gi.exists(ch) || !gi[ch].valid) continue;
            if (!gi[ch].ext_cmd)                 continue;   // chi ap cho trigger ngoai
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
          "cmd_trigger_checker: %0d AR du lieu duoc soi, %0d vi pham flow",
          n_checked, n_err), UVM_LOW)
    endfunction

endclass

`endif // CMD_TRIGGER_CHECKER_SV
