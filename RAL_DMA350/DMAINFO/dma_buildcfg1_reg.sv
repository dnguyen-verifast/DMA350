// DMA_BUILDCFG1 - Offset 0xB4 - RO - reset IMPLEMENTATION DEFINED
// DMA unit build configuration 1. HAS_TRIGSEL fixed=1; trigger counts are parameter dependent.
class dma_buildcfg1_reg extends uvm_reg;
    rand uvm_reg_field HAS_TRIGSEL;
    rand uvm_reg_field NUM_TRIGGER_OUT;
    rand uvm_reg_field NUM_TRIGGER_IN;

    `uvm_object_utils(dma_buildcfg1_reg)
    function new(string name = "dma_buildcfg1_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.HAS_TRIGSEL     = uvm_reg_field::type_id::create("HAS_TRIGSEL",, get_full_name());
        this.NUM_TRIGGER_OUT = uvm_reg_field::type_id::create("NUM_TRIGGER_OUT",, get_full_name());
        this.NUM_TRIGGER_IN  = uvm_reg_field::type_id::create("NUM_TRIGGER_IN",, get_full_name());

        //                      parent size lsb access volatile reset has_reset is_rand indiv_access
        this.HAS_TRIGSEL.configure(    this,1,16,"RO",0,1'h1,1,0,0);
        this.NUM_TRIGGER_OUT.configure(this,7, 9,"RO",0,7'h0,1,0,0);
        this.NUM_TRIGGER_IN.configure( this,9, 0,"RO",0,9'h0,1,0,0);
    endfunction
endclass
