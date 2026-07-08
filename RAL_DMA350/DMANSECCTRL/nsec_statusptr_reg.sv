// NSEC_STATUSPTR - Offset 0xF0 - RW - reset 0x00000000
// Non-secure Unit Status Pointer (selects status value visible in NSEC_STATUSVAL).
class nsec_statusptr_reg extends uvm_reg;
    rand uvm_reg_field NSECSTATUSPTR;

    `uvm_object_utils(nsec_statusptr_reg)
    function new(string name = "nsec_statusptr_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.NSECSTATUSPTR = uvm_reg_field::type_id::create("NSECSTATUSPTR",, get_full_name());
        //                    parent size lsb access volatile reset has_reset is_rand indiv_access
        this.NSECSTATUSPTR.configure(this,4,0,"RW",0,4'h0,1,0,0);
    endfunction
endclass
