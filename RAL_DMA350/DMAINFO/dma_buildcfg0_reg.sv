// DMA_BUILDCFG0 - Offset 0xB0 - RO - reset IMPLEMENTATION DEFINED
// DMA unit build configuration 0. All fields are config-parameter dependent (reset placeholders=0).
class dma_buildcfg0_reg extends uvm_reg;
    rand uvm_reg_field CHID_WIDTH;
    rand uvm_reg_field DATA_WIDTH;
    rand uvm_reg_field ADDR_WIDTH;
    rand uvm_reg_field NUM_CHANNELS;
    rand uvm_reg_field FRAMETYPE;

    `uvm_object_utils(dma_buildcfg0_reg)
    function new(string name = "dma_buildcfg0_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.CHID_WIDTH   = uvm_reg_field::type_id::create("CHID_WIDTH",, get_full_name());
        this.DATA_WIDTH   = uvm_reg_field::type_id::create("DATA_WIDTH",, get_full_name());
        this.ADDR_WIDTH   = uvm_reg_field::type_id::create("ADDR_WIDTH",, get_full_name());
        this.NUM_CHANNELS = uvm_reg_field::type_id::create("NUM_CHANNELS",, get_full_name());
        this.FRAMETYPE    = uvm_reg_field::type_id::create("FRAMETYPE",, get_full_name());

        //                  parent size lsb access volatile reset has_reset is_rand indiv_access
        this.CHID_WIDTH.configure(  this,5,20,"RO",0,5'h0,1,0,0);
        this.DATA_WIDTH.configure(  this,3,16,"RO",0,3'h0,1,0,0);
        this.ADDR_WIDTH.configure(  this,6,10,"RO",0,6'h0,1,0,0);
        this.NUM_CHANNELS.configure(this,6, 4,"RO",0,6'h0,1,0,0);
        this.FRAMETYPE.configure(   this,3, 0,"RO",0,3'h0,1,0,0);
    endfunction
endclass
