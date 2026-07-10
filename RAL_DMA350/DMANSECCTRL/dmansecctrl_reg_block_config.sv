// DMA Unit Non-secure Control Register Frame (DMANSECCTRL) - base 0x0200, size 0x0100
class dmansecctrl_reg_block_config extends uvm_reg_block;
    rand nsec_chintrstatus0_reg nsec_chintrstatus0;
    rand nsec_status_reg        nsec_status;
    rand nsec_ctrl_reg          nsec_ctrl;
    rand nsec_chptr_reg         nsec_chptr;
    rand nsec_chcfg_reg         nsec_chcfg;
    rand nsec_statusptr_reg     nsec_statusptr;
    rand nsec_statusval_reg     nsec_statusval;
    rand nsec_signalptr_reg     nsec_signalptr;
    rand nsec_signalval_reg     nsec_signalval;

    `uvm_object_utils(dmansecctrl_reg_block_config)
    function new(string name = "dmansecctrl_reg_block_config");
        super.new(name,build_coverage(UVM_NO_COVERAGE));
    endfunction
    virtual function void build();
        this.default_map = create_map(.name("DMANSECCTRL"),
                                        .base_addr(16'h0000),
                                        .n_bytes(4),
                                        .endian(UVM_LITTLE_ENDIAN),
                                        .byte_addressing(1));

        this.nsec_chintrstatus0 = nsec_chintrstatus0_reg::type_id::create("nsec_chintrstatus0",, get_full_name());
        this.nsec_chintrstatus0.configure(this, null, "");
        this.nsec_chintrstatus0.build();
        this.default_map.add_reg(this.nsec_chintrstatus0, `UVM_REG_ADDR_WIDTH'h000, "RO", 0, null);

        this.nsec_status = nsec_status_reg::type_id::create("nsec_status",, get_full_name());
        this.nsec_status.configure(this, null, "");
        this.nsec_status.build();
        this.default_map.add_reg(this.nsec_status, `UVM_REG_ADDR_WIDTH'h008, "RW", 0, null);

        this.nsec_ctrl = nsec_ctrl_reg::type_id::create("nsec_ctrl",, get_full_name());
        this.nsec_ctrl.configure(this, null, "");
        this.nsec_ctrl.build();
        this.default_map.add_reg(this.nsec_ctrl, `UVM_REG_ADDR_WIDTH'h00C, "RW", 0, null);

        this.nsec_chptr = nsec_chptr_reg::type_id::create("nsec_chptr",, get_full_name());
        this.nsec_chptr.configure(this, null, "");
        this.nsec_chptr.build();
        this.default_map.add_reg(this.nsec_chptr, `UVM_REG_ADDR_WIDTH'h014, "RW", 0, null);

        this.nsec_chcfg = nsec_chcfg_reg::type_id::create("nsec_chcfg",, get_full_name());
        this.nsec_chcfg.configure(this, null, "");
        this.nsec_chcfg.build();
        this.default_map.add_reg(this.nsec_chcfg, `UVM_REG_ADDR_WIDTH'h018, "RW", 0, null);

        this.nsec_statusptr = nsec_statusptr_reg::type_id::create("nsec_statusptr",, get_full_name());
        this.nsec_statusptr.configure(this, null, "");
        this.nsec_statusptr.build();
        this.default_map.add_reg(this.nsec_statusptr, `UVM_REG_ADDR_WIDTH'h0F0, "RW", 0, null);

        this.nsec_statusval = nsec_statusval_reg::type_id::create("nsec_statusval",, get_full_name());
        this.nsec_statusval.configure(this, null, "");
        this.nsec_statusval.build();
        this.default_map.add_reg(this.nsec_statusval, `UVM_REG_ADDR_WIDTH'h0F4, "RO", 0, null);

        this.nsec_signalptr = nsec_signalptr_reg::type_id::create("nsec_signalptr",, get_full_name());
        this.nsec_signalptr.configure(this, null, "");
        this.nsec_signalptr.build();
        this.default_map.add_reg(this.nsec_signalptr, `UVM_REG_ADDR_WIDTH'h0F8, "RW", 0, null);

        this.nsec_signalval = nsec_signalval_reg::type_id::create("nsec_signalval",, get_full_name());
        this.nsec_signalval.configure(this, null, "");
        this.nsec_signalval.build();
        this.default_map.add_reg(this.nsec_signalval, `UVM_REG_ADDR_WIDTH'h0FC, "RW", 0, null);
    endfunction
endclass
