// DMA Unit Security Configuration Register Frame (DMASECCFG) - base 0x0000, size 0x0100
class dmaseccfg_reg_block_config extends uvm_reg_block;
    rand scfg_chsec0_reg      scfg_chsec0;
    rand scfg_triginsec0_reg  scfg_triginsec0;
    rand scfg_trigoutsec0_reg scfg_trigoutsec0;
    rand scfg_ctrl_reg        scfg_ctrl;
    rand scfg_intrstatus_reg  scfg_intrstatus;

    `uvm_object_utils(dmaseccfg_reg_block_config)
    function new(string name = "dmaseccfg_reg_block_config");
        super.new(name,build_coverage(UVM_NO_COVERAGE));
    endfunction
    virtual function void build();
        this.default_map = create_map(.name("DMASECCFG"),
                                        .base_addr(16'h0000),
                                        .n_bytes(256),
                                        .endian(UVM_LITTLE_ENDIAN),
                                        .byte_addressing(1));

        this.scfg_chsec0 = scfg_chsec0_reg::type_id::create("scfg_chsec0",, get_full_name());
        this.scfg_chsec0.configure(this, null, "");
        this.scfg_chsec0.build();
        this.default_map.add_reg(this.scfg_chsec0, `UVM_REG_ADDR_WIDTH'h000, "RW", 0, null);

        this.scfg_triginsec0 = scfg_triginsec0_reg::type_id::create("scfg_triginsec0",, get_full_name());
        this.scfg_triginsec0.configure(this, null, "");
        this.scfg_triginsec0.build();
        this.default_map.add_reg(this.scfg_triginsec0, `UVM_REG_ADDR_WIDTH'h008, "RW", 0, null);

        this.scfg_trigoutsec0 = scfg_trigoutsec0_reg::type_id::create("scfg_trigoutsec0",, get_full_name());
        this.scfg_trigoutsec0.configure(this, null, "");
        this.scfg_trigoutsec0.build();
        this.default_map.add_reg(this.scfg_trigoutsec0, `UVM_REG_ADDR_WIDTH'h028, "RW", 0, null);

        this.scfg_ctrl = scfg_ctrl_reg::type_id::create("scfg_ctrl",, get_full_name());
        this.scfg_ctrl.configure(this, null, "");
        this.scfg_ctrl.build();
        this.default_map.add_reg(this.scfg_ctrl, `UVM_REG_ADDR_WIDTH'h040, "RW", 0, null);

        this.scfg_intrstatus = scfg_intrstatus_reg::type_id::create("scfg_intrstatus",, get_full_name());
        this.scfg_intrstatus.configure(this, null, "");
        this.scfg_intrstatus.build();
        this.default_map.add_reg(this.scfg_intrstatus, `UVM_REG_ADDR_WIDTH'h044, "RW", 0, null);
    endfunction
endclass
