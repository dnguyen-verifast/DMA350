// DMA Unit Secure Control Register Frame (DMASECCTRL) - base 0x0100, size 0x0100
class dmasecctrl_reg_block_config extends uvm_reg_block;
    rand sec_chintrstatus0_reg sec_chintrstatus0;
    rand sec_status_reg        sec_status;
    rand sec_ctrl_reg          sec_ctrl;
    rand sec_chptr_reg         sec_chptr;
    rand sec_chcfg_reg         sec_chcfg;
    rand sec_statusptr_reg     sec_statusptr;
    rand sec_statusval_reg     sec_statusval;
    rand sec_signalptr_reg     sec_signalptr;
    rand sec_signalval_reg     sec_signalval;

    `uvm_object_utils(dmasecctrl_reg_block_config)
    function new(string name = "dmasecctrl_reg_block_config");
        super.new(name,build_coverage(UVM_NO_COVERAGE));
    endfunction
    virtual function void build();
        this.default_map = create_map(.name("DMASECCTRL"),
                                        .base_addr(16'h0100),
                                        .n_bytes(256),
                                        .endian(UVM_LITTLE_ENDIAN),
                                        .byte_addressing(1));

        this.sec_chintrstatus0 = sec_chintrstatus0_reg::type_id::create("sec_chintrstatus0",, get_full_name());
        this.sec_chintrstatus0.configure(this, null, "");
        this.sec_chintrstatus0.build();
        this.default_map.add_reg(this.sec_chintrstatus0, `UVM_REG_ADDR_WIDTH'h000, "RO", 0, null);

        this.sec_status = sec_status_reg::type_id::create("sec_status",, get_full_name());
        this.sec_status.configure(this, null, "");
        this.sec_status.build();
        this.default_map.add_reg(this.sec_status, `UVM_REG_ADDR_WIDTH'h008, "RW", 0, null);

        this.sec_ctrl = sec_ctrl_reg::type_id::create("sec_ctrl",, get_full_name());
        this.sec_ctrl.configure(this, null, "");
        this.sec_ctrl.build();
        this.default_map.add_reg(this.sec_ctrl, `UVM_REG_ADDR_WIDTH'h00C, "RW", 0, null);

        this.sec_chptr = sec_chptr_reg::type_id::create("sec_chptr",, get_full_name());
        this.sec_chptr.configure(this, null, "");
        this.sec_chptr.build();
        this.default_map.add_reg(this.sec_chptr, `UVM_REG_ADDR_WIDTH'h014, "RW", 0, null);

        this.sec_chcfg = sec_chcfg_reg::type_id::create("sec_chcfg",, get_full_name());
        this.sec_chcfg.configure(this, null, "");
        this.sec_chcfg.build();
        this.default_map.add_reg(this.sec_chcfg, `UVM_REG_ADDR_WIDTH'h018, "RW", 0, null);

        this.sec_statusptr = sec_statusptr_reg::type_id::create("sec_statusptr",, get_full_name());
        this.sec_statusptr.configure(this, null, "");
        this.sec_statusptr.build();
        this.default_map.add_reg(this.sec_statusptr, `UVM_REG_ADDR_WIDTH'h0F0, "RW", 0, null);

        this.sec_statusval = sec_statusval_reg::type_id::create("sec_statusval",, get_full_name());
        this.sec_statusval.configure(this, null, "");
        this.sec_statusval.build();
        this.default_map.add_reg(this.sec_statusval, `UVM_REG_ADDR_WIDTH'h0F4, "RO", 0, null);

        this.sec_signalptr = sec_signalptr_reg::type_id::create("sec_signalptr",, get_full_name());
        this.sec_signalptr.configure(this, null, "");
        this.sec_signalptr.build();
        this.default_map.add_reg(this.sec_signalptr, `UVM_REG_ADDR_WIDTH'h0F8, "RW", 0, null);

        this.sec_signalval = sec_signalval_reg::type_id::create("sec_signalval",, get_full_name());
        this.sec_signalval.configure(this, null, "");
        this.sec_signalval.build();
        this.default_map.add_reg(this.sec_signalval, `UVM_REG_ADDR_WIDTH'h0FC, "RW", 0, null);
    endfunction
endclass
