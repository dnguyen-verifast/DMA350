// DMA_BUILDCFG2 - Offset 0xB8 - RO - reset IMPLEMENTATION DEFINED
// DMA unit build configuration 2. HAS_RET fixed=1; HAS_TZ = SECEXT_PRESENT; HAS_GPOSEL=0.
class dma_buildcfg2_reg extends uvm_reg;
    rand uvm_reg_field HAS_RET;
    rand uvm_reg_field HAS_TZ;
    rand uvm_reg_field HAS_GPOSEL;

    `uvm_object_utils(dma_buildcfg2_reg)
    function new(string name = "dma_buildcfg2_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.HAS_RET    = uvm_reg_field::type_id::create("HAS_RET",, get_full_name());
        this.HAS_TZ     = uvm_reg_field::type_id::create("HAS_TZ",, get_full_name());
        this.HAS_GPOSEL = uvm_reg_field::type_id::create("HAS_GPOSEL",, get_full_name());

        //               parent size lsb access volatile reset has_reset is_rand indiv_access
        this.HAS_RET.configure(   this,1,9,"RO",0,1'h1,1,0,0);
        this.HAS_TZ.configure(    this,1,8,"RO",0,1'h0,1,0,0);
        this.HAS_GPOSEL.configure(this,1,7,"RO",0,1'h0,1,0,0);
    endfunction
endclass
