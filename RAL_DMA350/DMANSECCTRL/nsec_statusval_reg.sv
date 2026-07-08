// NSEC_STATUSVAL - Offset 0xF4 - RO - reset 0x00000000
// Non-secure Unit Status Value selected by NSEC_STATUSPTR.
class nsec_statusval_reg extends uvm_reg;
    rand uvm_reg_field NSECSTATUSVAL;

    `uvm_object_utils(nsec_statusval_reg)
    function new(string name = "nsec_statusval_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.NSECSTATUSVAL = uvm_reg_field::type_id::create("NSECSTATUSVAL",, get_full_name());
        //                    parent size lsb access volatile reset has_reset is_rand indiv_access
        this.NSECSTATUSVAL.configure(this,32,0,"RO",1,32'h0,1,0,0);
    endfunction
endclass
