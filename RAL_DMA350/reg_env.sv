class reg_env extends uvm_env;
    `uvm_component_utils(reg_env)
    function new(string name = "reg_env", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    ral_dma350      m_ral_model;
    reg2apb_adapter m_reg2apb;
    uvm_reg_predictor #(apb_seq_item) m_predictor;

//  my_agent m_agent;

    virtual function void build_phase(uvm_phase phase);
        string hdl_root;
        int    num_ch = 8;
        int    gpo_w  = 4;
        super.build_phase(phase);
        m_ral_model = ral_dma350::type_id::create("m_ral_model", this);
        m_reg2apb   = reg2apb_adapter::type_id::create("m_reg2apb");
        m_predictor = uvm_reg_predictor #(apb_seq_item)::type_id::create("m_predictor",this);

        // Tham so build cua DUT (tb_top publish). Phai gan TRUOC build() vi
        // build() dung num_channels de sinh mang DMACH va gpo_width de dat slice.
        void'(uvm_config_db#(int)::get(this,"","num_channels",num_ch));
        void'(uvm_config_db#(int)::get(this,"","gpo_width",   gpo_w));
        m_ral_model.num_channels = num_ch;
        m_ral_model.gpo_width    = gpo_w;

        m_ral_model.build();

        // Goc HDL path cho BACKDOOR: tb_top set config_db string "hdl_root"
        // (vd "dma350_tb_top.u_dut"). Ghep voi hdl_path cua block/reg
        // (g_ch[n].u_regs + slice) thanh duong dan day du toi RTL.
        //
        // FATAL chu khong WARNING: thieu root thi peek() tra ve 0 kem UVM_ERROR
        // ma status van UVM_IS_OK -> scoreboard so sanh voi 0 va "pass" gia.
        if (!uvm_config_db#(string)::get(this,"","hdl_root",hdl_root) || hdl_root == "")
            `uvm_fatal("REG_ENV",
              "thieu 'hdl_root' trong config_db : backdoor RAL khong the hoat dong")

        m_ral_model.add_hdl_path(hdl_root);
        m_ral_model.lock_model();   // lock DUY NHAT o day, sau khi da co root path

        uvm_config_db #(ral_dma350)::set(null,"*","m_ral_model",m_ral_model);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_predictor.map = m_ral_model.default_map;
        m_predictor.adapter = m_reg2apb;
    endfunction

    //--------------------------------------------------------------------------
    // Kiem tra moi HDL path cua RAL co ton tai trong hierarchy da elaborate.
    // Khong co buoc nay, mot typo ten bien RTL chi lo ra luc peek() giua test
    // dai, duoi dang gia tri rac hoac UVM_ERROR kho truy nguon.
    //
    // Can quyen truy cap HDL: Questa -voptargs=+acc=npr, VCS -debug_access+all.
    //--------------------------------------------------------------------------
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        uvm_reg regs[$];
        int n_bkdr = 0, n_none = 0, n_bad = 0;
        super.end_of_elaboration_phase(phase);

        m_ral_model.get_registers(regs);
        foreach (regs[i]) begin
            uvm_hdl_path_concat paths[$];

            // Thanh ghi co backdoor tuy bien (vd const_reg_backdoor cho localparam)
            // khong co hdl path -- bo qua, khong phai loi.
            if (regs[i].get_backdoor() != null) begin
                n_bkdr++;
                continue;
            end
            if (!regs[i].has_hdl_path("RTL")) begin
                n_none++;
                `uvm_info("REG_BKDR", $sformatf("%s : frontdoor-only (khong co backdoor)",
                          regs[i].get_full_name()), UVM_HIGH)
                continue;
            end

            regs[i].get_full_hdl_path(paths, "RTL");
            foreach (paths[p])
                foreach (paths[p].slices[s])
                    if (!uvm_hdl_check_path(paths[p].slices[s].path)) begin
                        n_bad++;
                        `uvm_error("REG_BKDR", $sformatf("%s : HDL path khong ton tai : %s",
                                   regs[i].get_full_name(), paths[p].slices[s].path))
                    end
            n_bkdr++;
        end

        `uvm_info("REG_BKDR", $sformatf(
            "RAL backdoor: %0d reg co backdoor, %0d reg frontdoor-only, %0d path hong",
            n_bkdr, n_none, n_bad), UVM_LOW)
    endfunction
endclass
