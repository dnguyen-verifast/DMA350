// SEC_STATUSPTR - Offset 0xF0 - RW - reset 0x00000000
// Secure Unit Status Pointer (selects status value visible in SEC_STATUSVAL).
class sec_statusptr_reg extends uvm_reg;
    rand uvm_reg_field SECSTATUSPTR;

    `uvm_object_utils(sec_statusptr_reg)
    function new(string name = "sec_statusptr_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.SECSTATUSPTR = uvm_reg_field::type_id::create("SECSTATUSPTR",, get_full_name());
        //                   parent size lsb access volatile reset has_reset is_rand indiv_access
        this.SECSTATUSPTR.configure(this,4,0,"RW",0,4'h0,1,0,0);
    endfunction
endclass
