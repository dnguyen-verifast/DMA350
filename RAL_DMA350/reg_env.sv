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
        super.build_phase(phase);
        m_ral_model = ral_dma350::type_id::create("m_ral_model", this);
        m_reg2apb   = reg2apb_adapter::type_id::create("m_reg2apb");
        m_predictor = uvm_reg_predictor #(apb_seq_item)::type_id::create("m_predictor",this);

        m_ral_model.build();

        // Goc HDL path cho BACKDOOR: tb_top set config_db string "hdl_root"
        // (vd "dma350_tb_top.u_dut"). Ghep voi hdl_path cua block/reg
        // (g_ch[0].u_regs + slice) thanh duong dan day du toi RTL.
        if (uvm_config_db#(string)::get(this,"","hdl_root",hdl_root) && hdl_root != "")
            m_ral_model.add_hdl_path(hdl_root);
        else
            `uvm_warning("REG_ENV",
              "khong co 'hdl_root' trong config_db : backdoor peek se KHONG hoat dong")

        m_ral_model.lock_model();
        uvm_config_db #(ral_dma350)::set(null,"*","m_ral_model",m_ral_model);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_predictor.map = m_ral_model.default_map;
        m_predictor.adapter = m_reg2apb;
    endfunction
endclass
