// CH_WRKREGPTR - Offset 0x88 - RW - reset 0x00000000
// Channel Working Register Pointer (selects work register visible in CH_WRKREGVAL).
class ch_wrkregptr_reg extends uvm_reg;
    rand uvm_reg_field WRKREGPTR;

    `uvm_object_utils(ch_wrkregptr_reg)
    function new(string name = "ch_wrkregptr_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.WRKREGPTR = uvm_reg_field::type_id::create("WRKREGPTR",, get_full_name());
        //                parent size lsb access volatile reset has_reset is_rand indiv_access
        this.WRKREGPTR.configure(this,4,0,"RW",0,4'h0,1,0,0);
    endfunction
endclass
