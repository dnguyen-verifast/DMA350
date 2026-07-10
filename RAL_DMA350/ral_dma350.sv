class ral_dma350 extends uvm_reg_block;
    rand dmach_reg_block_config       dmach[];   // 1 frame / channel, size = num_channels
    rand dmaseccfg_reg_block_config   dmaseccfg;
    rand dmasecctrl_reg_block_config  dmasecctrl;
    rand dmansecctrl_reg_block_config dmansecctrl;
    rand dmainfo_reg_block_config     dmainfo;

    // Tham so build cua DUT. reg_env gan tu config_db TRUOC khi goi build().
    int unsigned num_channels = 8;   // dma350_top #(.NUM_CHANNELS())
    int unsigned gpo_width    = 4;   // dma350_top #(.GPO_WIDTH())

    `uvm_object_utils(ral_dma350)
    function new(string name="ral_dma350");
        super.new(name);
    endfunction

    // LUU Y: build() KHONG goi lock_model(). reg_env phai add_hdl_path(hdl_root)
    // roi moi lock_model() -- xem reg_env.sv.
    function void build();
        this.default_map = create_map(.name("ral_dma350"),
                                        .base_addr(0),
                                        .n_bytes(4),
                                        .endian(UVM_LITTLE_ENDIAN),
                                        .byte_addressing(0));

        // DMASECCFG frame @ 0x0000
        this.dmaseccfg = dmaseccfg_reg_block_config::type_id::create("dmaseccfg",, get_full_name());
        this.dmaseccfg.configure(.parent(this),
                                    .hdl_path(""));
        this.dmaseccfg.build();
        this.default_map.add_submap(.child_map(this.dmaseccfg.default_map),
                                    .offset(`UVM_REG_ADDR_WIDTH'h0000));

        // DMASECCTRL frame @ 0x0100
        this.dmasecctrl = dmasecctrl_reg_block_config::type_id::create("dmasecctrl",, get_full_name());
        this.dmasecctrl.configure(.parent(this),
                                    .hdl_path(""));
        this.dmasecctrl.build();
        this.default_map.add_submap(.child_map(this.dmasecctrl.default_map),
                                    .offset(`UVM_REG_ADDR_WIDTH'h0100));

        // DMANSECCTRL frame @ 0x0200
        this.dmansecctrl = dmansecctrl_reg_block_config::type_id::create("dmansecctrl",, get_full_name());
        this.dmansecctrl.configure(.parent(this),
                                    .hdl_path(""));
        this.dmansecctrl.build();
        this.default_map.add_submap(.child_map(this.dmansecctrl.default_map),
                                    .offset(`UVM_REG_ADDR_WIDTH'h0200));

        // DMAINFO frame @ 0x0F00
        this.dmainfo = dmainfo_reg_block_config::type_id::create("dmainfo",, get_full_name());
        this.dmainfo.configure(.parent(this),
                                .hdl_path(""));
        this.dmainfo.build();
        this.default_map.add_submap(.child_map(this.dmainfo.default_map),
                                    .offset(`UVM_REG_ADDR_WIDTH'h0F00));

        // DMACH<n> frame @ 0x1000 + n*0x100, n = 0 .. num_channels-1
        // HDL path: register-frame cua channel n trong dma350_top
        // (generate g_ch[n] -> dma350_ch_regs u_regs). Goc (dma350_tb_top.u_dut)
        // do reg_env add_hdl_path() tu config_db "hdl_root".
        this.dmach = new[num_channels];
        foreach (this.dmach[i]) begin
            this.dmach[i] = dmach_reg_block_config::type_id::create(
                                $sformatf("dmach%0d", i),, get_full_name());
            this.dmach[i].gpo_width = this.gpo_width;
            this.dmach[i].configure(.parent(this),
                                    .hdl_path($sformatf("g_ch[%0d].u_regs", i)));
            this.dmach[i].build();
            this.default_map.add_submap(.child_map(this.dmach[i].default_map),
                                        .offset(`UVM_REG_ADDR_WIDTH'h1000 +
                                                i * `UVM_REG_ADDR_WIDTH'h100));
        end
    endfunction
endclass
