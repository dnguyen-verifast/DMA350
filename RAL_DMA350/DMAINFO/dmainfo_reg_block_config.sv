// DMA Unit Information Register Frame (DMAINFO) - base 0x0F00, size 0x0100
class dmainfo_reg_block_config extends uvm_reg_block;
    rand dma_buildcfg0_reg dma_buildcfg0;
    rand dma_buildcfg1_reg dma_buildcfg1;
    rand dma_buildcfg2_reg dma_buildcfg2;
    rand iidr_reg          iidr;
    rand aidr_reg          aidr;
    rand pidr4_reg         pidr4;
    rand pidr0_reg         pidr0;
    rand pidr1_reg         pidr1;
    rand pidr2_reg         pidr2;
    rand pidr3_reg         pidr3;
    rand cidr0_reg         cidr0;
    rand cidr1_reg         cidr1;
    rand cidr2_reg         cidr2;
    rand cidr3_reg         cidr3;

    `uvm_object_utils(dmainfo_reg_block_config)
    function new(string name = "dmainfo_reg_block_config");
        super.new(name,build_coverage(UVM_NO_COVERAGE));
    endfunction
    virtual function void build();
        this.default_map = create_map(.name("DMAINFO"),
                                        .base_addr(16'h0F00),
                                        .n_bytes(256),
                                        .endian(UVM_LITTLE_ENDIAN),
                                        .byte_addressing(1));

        this.dma_buildcfg0 = dma_buildcfg0_reg::type_id::create("dma_buildcfg0",, get_full_name());
        this.dma_buildcfg0.configure(this, null, "");
        this.dma_buildcfg0.build();
        this.default_map.add_reg(this.dma_buildcfg0, `UVM_REG_ADDR_WIDTH'h0B0, "RO", 0, null);

        this.dma_buildcfg1 = dma_buildcfg1_reg::type_id::create("dma_buildcfg1",, get_full_name());
        this.dma_buildcfg1.configure(this, null, "");
        this.dma_buildcfg1.build();
        this.default_map.add_reg(this.dma_buildcfg1, `UVM_REG_ADDR_WIDTH'h0B4, "RO", 0, null);

        this.dma_buildcfg2 = dma_buildcfg2_reg::type_id::create("dma_buildcfg2",, get_full_name());
        this.dma_buildcfg2.configure(this, null, "");
        this.dma_buildcfg2.build();
        this.default_map.add_reg(this.dma_buildcfg2, `UVM_REG_ADDR_WIDTH'h0B8, "RO", 0, null);

        this.iidr = iidr_reg::type_id::create("iidr",, get_full_name());
        this.iidr.configure(this, null, "");
        this.iidr.build();
        this.default_map.add_reg(this.iidr, `UVM_REG_ADDR_WIDTH'h0C8, "RO", 0, null);

        this.aidr = aidr_reg::type_id::create("aidr",, get_full_name());
        this.aidr.configure(this, null, "");
        this.aidr.build();
        this.default_map.add_reg(this.aidr, `UVM_REG_ADDR_WIDTH'h0CC, "RO", 0, null);

        this.pidr4 = pidr4_reg::type_id::create("pidr4",, get_full_name());
        this.pidr4.configure(this, null, "");
        this.pidr4.build();
        this.default_map.add_reg(this.pidr4, `UVM_REG_ADDR_WIDTH'h0D0, "RO", 0, null);

        this.pidr0 = pidr0_reg::type_id::create("pidr0",, get_full_name());
        this.pidr0.configure(this, null, "");
        this.pidr0.build();
        this.default_map.add_reg(this.pidr0, `UVM_REG_ADDR_WIDTH'h0E0, "RO", 0, null);

        this.pidr1 = pidr1_reg::type_id::create("pidr1",, get_full_name());
        this.pidr1.configure(this, null, "");
        this.pidr1.build();
        this.default_map.add_reg(this.pidr1, `UVM_REG_ADDR_WIDTH'h0E4, "RO", 0, null);

        this.pidr2 = pidr2_reg::type_id::create("pidr2",, get_full_name());
        this.pidr2.configure(this, null, "");
        this.pidr2.build();
        this.default_map.add_reg(this.pidr2, `UVM_REG_ADDR_WIDTH'h0E8, "RO", 0, null);

        this.pidr3 = pidr3_reg::type_id::create("pidr3",, get_full_name());
        this.pidr3.configure(this, null, "");
        this.pidr3.build();
        this.default_map.add_reg(this.pidr3, `UVM_REG_ADDR_WIDTH'h0EC, "RO", 0, null);

        this.cidr0 = cidr0_reg::type_id::create("cidr0",, get_full_name());
        this.cidr0.configure(this, null, "");
        this.cidr0.build();
        this.default_map.add_reg(this.cidr0, `UVM_REG_ADDR_WIDTH'h0F0, "RO", 0, null);

        this.cidr1 = cidr1_reg::type_id::create("cidr1",, get_full_name());
        this.cidr1.configure(this, null, "");
        this.cidr1.build();
        this.default_map.add_reg(this.cidr1, `UVM_REG_ADDR_WIDTH'h0F4, "RO", 0, null);

        this.cidr2 = cidr2_reg::type_id::create("cidr2",, get_full_name());
        this.cidr2.configure(this, null, "");
        this.cidr2.build();
        this.default_map.add_reg(this.cidr2, `UVM_REG_ADDR_WIDTH'h0F8, "RO", 0, null);

        this.cidr3 = cidr3_reg::type_id::create("cidr3",, get_full_name());
        this.cidr3.configure(this, null, "");
        this.cidr3.build();
        this.default_map.add_reg(this.cidr3, `UVM_REG_ADDR_WIDTH'h0FC, "RO", 0, null);
    endfunction
endclass
