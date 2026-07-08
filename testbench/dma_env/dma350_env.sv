`ifndef DMA350_ENV_INCLUDE_
`define DMA350_ENV_INCLUDE_
class dma350_env extends uvm_env;
    `uvm_component_utils(dma350_env)
    
    dma350_scoreboard dma350_scb_h;

    axi5_slave_agent axi5_agt_slv0_h;
    axi5_slave_agent_config axi5_slave_agent_config_h0;

    axi5_slave_agent axi5_agent_slv1_h;
    axi5_slave_agent_config axi5_slave_agent_config_h1;

    apb_agent_master apb_agent_mst_h;

    axis_master_agent axis_agent_in_h;
    axis_master_cfg axis_master_cfg_in_h;

    axis_slave_agent axis_agent_out_h;
    axis_slave_cfg axis_slave_cfg_out_h;

    boot_agent boot_agent_h;
    boot_agent_cfg boot_agent_cfg_h;

    dma_irq_agent dma_irq_agent_h;
    dma_irq_config dma_irq_config_h;

    crlp_agent crlp_agent_h;
    crlp_config crlp_config_h;

    dma350_sc_agent dma350_sc_agent_h;
    dma350_sc_cfg dma350_sc_cfg_h;

    reg_env reg_env_h;

    // Virtual sequencer: virtual sequence dieu khien toan testbench qua day
    dma350_virtual_sequencer v_seqr_h;


    function new(string name="dma350_env",uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        //---------------------------------------------------------------------
        // (A) Lay config cua tung agent tu config_db (do test/top set vao)
        //---------------------------------------------------------------------
        if(!uvm_config_db #(axi5_slave_agent_config)::get(this,"","axi5_slave_agent_config0",axi5_slave_agent_config_h0)) begin
            `uvm_fatal("FATAL_ENV_AGENT_CONFIG", $sformatf("Couldn't get the axi5_agent_config from config_db"))
        end

        if(!uvm_config_db #(axi5_slave_agent_config)::get(this,"","axi5_slave_agent_config1",axi5_slave_agent_config_h1)) begin
            `uvm_fatal("FATAL_ENV_AGENT_CONFIG", $sformatf("Couldn't get the axi5_agent_config from config_db"))
        end

        if(!uvm_config_db #(axis_master_cfg)::get(this,"","axis_master_cfg_in",axis_master_cfg_in_h)) begin
            `uvm_fatal("FATAL_ENV_AGENT_CONFIG", $sformatf("Couldn't get the axis_master_cfg from config_db"))
        end

        if(!uvm_config_db #(axis_slave_cfg)::get(this,"","axis_slave_cfg_out",axis_slave_cfg_out_h)) begin
            `uvm_fatal("FATAL_ENV_AGENT_CONFIG", $sformatf("Couldn't get the axis_slave_cfg from config_db"))
        end

        if(!uvm_config_db #(boot_agent_cfg)::get(this,"","boot_agent_cfg",boot_agent_cfg_h)) begin
            `uvm_fatal("FATAL_ENV_AGENT_CONFIG", $sformatf("Couldn't get the boot_agent_cfg from config_db"))
        end

        if(!uvm_config_db #(dma_irq_config)::get(this,"","dma_irq_config",dma_irq_config_h)) begin
            `uvm_fatal("FATAL_ENV_AGENT_CONFIG", $sformatf("Couldn't get the dma_irq_config from config_db"))
        end

        if(!uvm_config_db #(crlp_config)::get(this,"","crlp_config",crlp_config_h)) begin
            `uvm_fatal("FATAL_ENV_AGENT_CONFIG", $sformatf("Couldn't get the crlp_config from config_db"))
        end

        if(!uvm_config_db #(dma350_sc_cfg)::get(this,"","dma350_sc_cfg",dma350_sc_cfg_h)) begin
            `uvm_fatal("FATAL_ENV_AGENT_CONFIG", $sformatf("Couldn't get the dma350_sc_cfg from config_db"))
        end

        //---------------------------------------------------------------------
        // (B) Phan phoi config XUONG tung agent qua config_db.
        //     Cac agent nay lay cfg bang uvm_config_db#(...)::get(this,"","cfg",cfg)
        //     trong build_phase cua CHINH no => env PHAI set TRUOC khi agent build
        //     (build_phase con chay sau khi build_phase cha ket thuc, nen set o day
        //     la du som). Key phai la "cfg" + dung ten instance cua agent.
        //---------------------------------------------------------------------
        uvm_config_db#(axis_master_cfg)::set(this, "axis_agent_in_h",   "cfg", axis_master_cfg_in_h);
        uvm_config_db#(axis_slave_cfg )::set(this, "axis_agent_out_h",  "cfg", axis_slave_cfg_out_h);
        uvm_config_db#(boot_agent_cfg )::set(this, "boot_agent_h",      "cfg", boot_agent_cfg_h);
        uvm_config_db#(dma_irq_config )::set(this, "dma_irq_agent_h",   "cfg", dma_irq_config_h);
        uvm_config_db#(crlp_config    )::set(this, "crlp_agent_h",      "cfg", crlp_config_h);
        uvm_config_db#(dma350_sc_cfg  )::set(this, "dma350_sc_agent_h", "cfg", dma350_sc_cfg_h);

        //---------------------------------------------------------------------
        // (C) Tao cac component
        //---------------------------------------------------------------------
        dma350_scb_h      = dma350_scoreboard::type_id::create("dma350_scb_h",this);
        axi5_agt_slv0_h   = axi5_slave_agent::type_id::create("axi5_agt_slv0_h",this);
        axi5_agent_slv1_h = axi5_slave_agent::type_id::create("axi5_agent_slv1_h",this);
        apb_agent_mst_h   = apb_agent_master::type_id::create("apb_agent_mst_h",this);
        axis_agent_in_h   = axis_master_agent::type_id::create("axis_agent_in_h",this);
        axis_agent_out_h  = axis_slave_agent::type_id::create("axis_agent_out_h",this);
        boot_agent_h      = boot_agent::type_id::create("boot_agent_h",this);
        dma_irq_agent_h   = dma_irq_agent::type_id::create("dma_irq_agent_h",this);
        crlp_agent_h      = crlp_agent::type_id::create("crlp_agent_h",this);
        dma350_sc_agent_h = dma350_sc_agent::type_id::create("dma350_sc_agent_h",this);

        reg_env_h = reg_env::type_id::create("reg_env_h",this);

        v_seqr_h = dma350_virtual_sequencer::type_id::create("v_seqr_h",this);

        //---------------------------------------------------------------------
        // (D) axi5_slave_agent lay cfg qua BIEN THANH VIEN (axi5_slave_agent_cfg_h)
        //     va kiem null NGAY trong build_phase cua no. Vi vay phai gan handle
        //     ngay tai day (sau create, van con trong build_phase cua env) chu
        //     KHONG the doi den connect_phase (luc do build cua agent da fatal).
        //---------------------------------------------------------------------
        axi5_agt_slv0_h.axi5_slave_agent_cfg_h   = axi5_slave_agent_config_h0;
        axi5_agent_slv1_h.axi5_slave_agent_cfg_h = axi5_slave_agent_config_h1;
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        //=====================================================================
        // AXI5 slave 0 (M0 data-path) : 5 kenh monitor -> scoreboard FIFO
        //=====================================================================
        axi5_agt_slv0_h.axi5_slave_mon_proxy_h.axi5_slave_read_address_analysis_port.connect(
            dma350_scb_h.axi5_slave0_read_address_analysis_fifo.analysis_export);
        axi5_agt_slv0_h.axi5_slave_mon_proxy_h.axi5_slave_read_data_analysis_port.connect(
            dma350_scb_h.axi5_slave0_read_data_analysis_fifo.analysis_export);
        axi5_agt_slv0_h.axi5_slave_mon_proxy_h.axi5_slave_write_address_analysis_port.connect(
            dma350_scb_h.axi5_slave0_write_address_analysis_fifo.analysis_export);
        axi5_agt_slv0_h.axi5_slave_mon_proxy_h.axi5_slave_write_data_analysis_port.connect(
            dma350_scb_h.axi5_slave0_write_data_analysis_fifo.analysis_export);
        axi5_agt_slv0_h.axi5_slave_mon_proxy_h.axi5_slave_write_response_analysis_port.connect(
            dma350_scb_h.axi5_slave0_write_response_analysis_fifo.analysis_export);

        //=====================================================================
        // AXI5 slave 1 (M1 data-path) : 5 kenh monitor -> scoreboard FIFO
        //=====================================================================
        axi5_agent_slv1_h.axi5_slave_mon_proxy_h.axi5_slave_read_address_analysis_port.connect(
            dma350_scb_h.axi5_slave1_read_address_analysis_fifo.analysis_export);
        axi5_agent_slv1_h.axi5_slave_mon_proxy_h.axi5_slave_read_data_analysis_port.connect(
            dma350_scb_h.axi5_slave1_read_data_analysis_fifo.analysis_export);
        axi5_agent_slv1_h.axi5_slave_mon_proxy_h.axi5_slave_write_address_analysis_port.connect(
            dma350_scb_h.axi5_slave1_write_address_analysis_fifo.analysis_export);
        axi5_agent_slv1_h.axi5_slave_mon_proxy_h.axi5_slave_write_data_analysis_port.connect(
            dma350_scb_h.axi5_slave1_write_data_analysis_fifo.analysis_export);
        axi5_agent_slv1_h.axi5_slave_mon_proxy_h.axi5_slave_write_response_analysis_port.connect(
            dma350_scb_h.axi5_slave1_write_response_analysis_fifo.analysis_export);

        //=====================================================================
        // APB register bus (monitor) -> scoreboard (golden-intent / readback).
        // mon_port_m la analysis_port muc agent, duoc feed tu apb_mon_m.mon_port_m
        // (xem apb_agent_master.connect_phase). Analysis_port fan-out duoc nen
        // cung port nay con phuc vu RAL predict ben duoi.
        //=====================================================================
        apb_agent_mst_h.mon_port_m.connect(dma350_scb_h.apb_master_analysis_fifo_h0.analysis_export);

        //=====================================================================
        // AXI-Stream : in (master, peripheral->DMA) va out (slave, DMA->peripheral)
        //   scoreboard.process_stream(t, is_master): master=1, slave=0
        //=====================================================================
        axis_agent_in_h.ap.connect (dma350_scb_h.axis_master_analysis_fifo_h0.analysis_export);
        axis_agent_out_h.ap.connect(dma350_scb_h.axis_slave_analysis_fifo_h0.analysis_export);

        //=====================================================================
        // Boot / CRLP (clock-reset-lowpower) -> scoreboard
        //=====================================================================
        boot_agent_h.ap.connect(dma350_scb_h.boot_analysis_fifo_h0.analysis_export);
        crlp_agent_h.ap.connect(dma350_scb_h.crlp_analysis_fifo_h0.analysis_export);

        //=====================================================================
        // Status/Control -> scoreboard.
        // process_status_control() doc snapshot PER-CYCLE (ch_enabled/err/...),
        // do monitor phat qua ap_status (snapshot khi bat ky bit status doi),
        // KHONG phai ap (item stop/pause-ack). Dung dung ap_status.
        //=====================================================================
        dma350_sc_agent_h.ap_status.connect(dma350_scb_h.dma350_sta_ctrl_analysis_fifo_h0.analysis_export);

        //=====================================================================
        // RAL : frontdoor sequencer + auto-predict + handoff model cho backdoor
        //=====================================================================
        reg_env_h.m_ral_model.default_map.set_sequencer(
            apb_agent_mst_h.apb_sequencer_master_h, reg_env_h.m_reg2apb);
        // Auto-predict: RAL tu cap nhat mirror khi truy cap frontdoor.
        // NOTE: prediction TUONG MINH qua reg_env_h.m_predictor.bus_in yeu cau
        // monitor phat CUNG kieu voi predictor (uvm_reg_predictor#(apb_seq_item)),
        // nhung apb_monitor_master phat apb_seq_item_master => hai kieu KHAC nhau
        // nen khong connect truc tiep duoc. Muon dung explicit predictor: param
        // uvm_reg_predictor bang apb_seq_item_master hoac them lop converter.
        reg_env_h.m_ral_model.default_map.set_auto_predict(1);

        // Cap RAL model cho scoreboard de peek BACKDOOR (ral_peek). Gan o
        // connect_phase (chay sau khi reg_env.build tao xong m_ral_model).
        // Luu y: scoreboard.connect_phase (kiem HDL path, set m_backdoor_ok) chay
        // TRUOC connect_phase nay (bottom-up) nen se canh bao "RAL null"; runtime
        // ral_peek van hoat dong vi chi phu thuoc m_ral_dma_model + has_hdl_path.
        // Muon check HDL-path o connect: test nen set config_db#(ral_dma350)
        // key "ral_dma_model" TRUOC build cua scoreboard.
        dma350_scb_h.m_ral_dma_model = reg_env_h.m_ral_model;

        //=====================================================================
        // VIRTUAL SEQUENCER : gan handle sequencer cua tung agent (chi khi
        // agent ACTIVE - passive khong tao sequencer, handle giu null).
        // dma_irq_agent luon passive -> khong co sequencer.
        //=====================================================================
        v_seqr_h.apb_seqr_h = apb_agent_mst_h.apb_sequencer_master_h;

        if (axi5_slave_agent_config_h0.is_active == UVM_ACTIVE) begin
            v_seqr_h.axi5_slv0_write_seqr_h = axi5_agt_slv0_h.axi5_slave_write_seqr_h;
            v_seqr_h.axi5_slv0_read_seqr_h  = axi5_agt_slv0_h.axi5_slave_read_seqr_h;
        end
        if (axi5_slave_agent_config_h1.is_active == UVM_ACTIVE) begin
            v_seqr_h.axi5_slv1_write_seqr_h = axi5_agent_slv1_h.axi5_slave_write_seqr_h;
            v_seqr_h.axi5_slv1_read_seqr_h  = axi5_agent_slv1_h.axi5_slave_read_seqr_h;
        end
        if (axis_master_cfg_in_h.is_active == UVM_ACTIVE)
            v_seqr_h.axis_mst_seqr_h = axis_agent_in_h.sqr;
        if (axis_slave_cfg_out_h.is_active == UVM_ACTIVE)
            v_seqr_h.axis_slv_seqr_h = axis_agent_out_h.sqr;
        if (boot_agent_cfg_h.is_active == UVM_ACTIVE)
            v_seqr_h.boot_seqr_h = boot_agent_h.sqr;
        if (crlp_config_h.is_active == UVM_ACTIVE)
            v_seqr_h.crlp_seqr_h = crlp_agent_h.sqr;
        if (dma350_sc_cfg_h.is_active == UVM_ACTIVE)
            v_seqr_h.sc_seqr_h = dma350_sc_agent_h.sqr;

        //=====================================================================
        // GAP con thieu trong codebase (chua wire duoc vi thieu doi tac):
        //   1) dma_irq_agent_h.ap phat dma_irq_item, nhung scoreboard CHUA co
        //      analysis_fifo tieu thu IRQ. Can them irq_analysis_fifo +
        //      process_irq() vao dma350_scoreboard (doi chieu DONE/ERR interrupt
        //      voi STATUS) roi connect: dma_irq_agent_h.ap.connect(...).
        //   2) scoreboard.dma_trig_analysis_fifo_h0 (dma_trig_item) CHUA co agent
        //      trigger phat item. Can bo sung VIP trigger (dma_trig_item) roi
        //      connect vao FIFO nay.
        //=====================================================================
    endfunction

endclass
`endif