class ral_dma350 extends uvm_reg_block;
    rand dmach_reg_block_config dmach;
    rand dmaseccfg_reg_block_config dmaseccfg;
    rand dmasecctrl_reg_block_config dmasecctrl;
    rand dmansecctrl_reg_block_config dmansecctrl;
    rand dmainfo_reg_block_config dmainfo;
    `uvm_object_utils(ral_dma350)
    function new(string name="ral_dma350");
        super.new(name);
    endfunction
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

        // DMACH Channel 0 frame @ 0x1000
        // HDL path: instance register-frame cua channel 0 trong dma350_top
        // (generate g_ch[0] -> dma350_ch_regs u_regs). Goc (dma350_tb_top.u_dut)
        // do reg_env add_hdl_path() tu config_db "hdl_root".
        this.dmach = dmach_reg_block_config::type_id::create("dmach",, get_full_name());
        this.dmach.configure(.parent(this),
                                .hdl_path("g_ch[0].u_regs"));
        this.dmach.build();
        this.default_map.add_submap(.child_map(this.dmach.default_map),
                                    .offset(`UVM_REG_ADDR_WIDTH'h1000));

        this.lock_model();
    endfunction
endclass
