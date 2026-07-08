// NSEC_SIGNALPTR - Offset 0xF8 - RW - reset 0x00000000
// Non-secure Unit Signal Pointer (selects interface signals visible in NSEC_SIGNALVAL).
class nsec_signalptr_reg extends uvm_reg;
    rand uvm_reg_field NSECSIGNALPTR;

    `uvm_object_utils(nsec_signalptr_reg)
    function new(string name = "nsec_signalptr_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.NSECSIGNALPTR = uvm_reg_field::type_id::create("NSECSIGNALPTR",, get_full_name());
        //                    parent size lsb access volatile reset has_reset is_rand indiv_access
        this.NSECSIGNALPTR.configure(this,4,0,"RW",0,4'h0,1,0,0);
    endfunction
endclass
