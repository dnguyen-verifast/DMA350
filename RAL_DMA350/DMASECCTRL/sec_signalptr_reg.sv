// SEC_SIGNALPTR - Offset 0xF8 - RW - reset 0x00000000
// Secure Unit Signal Pointer (selects interface signals visible in SEC_SIGNALVAL).
class sec_signalptr_reg extends uvm_reg;
    rand uvm_reg_field SECSIGNALPTR;

    `uvm_object_utils(sec_signalptr_reg)
    function new(string name = "sec_signalptr_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.SECSIGNALPTR = uvm_reg_field::type_id::create("SECSIGNALPTR",, get_full_name());
        //                   parent size lsb access volatile reset has_reset is_rand indiv_access
        this.SECSIGNALPTR.configure(this,4,0,"RW",0,4'h0,1,0,0);
    endfunction
endclass
