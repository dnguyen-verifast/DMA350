// NSEC_CHPTR - Offset 0x14 - RW - reset 0x00000000
// Non-secure Channel Pointer: selects channel configured via NSEC_CHCFG.
class nsec_chptr_reg extends uvm_reg;
    rand uvm_reg_field CHPTR;

    `uvm_object_utils(nsec_chptr_reg)
    function new(string name = "nsec_chptr_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.CHPTR = uvm_reg_field::type_id::create("CHPTR",, get_full_name());
        //            parent size lsb access volatile reset has_reset is_rand indiv_access
        this.CHPTR.configure(this,6,0,"RW",0,6'h0,1,0,0);
    endfunction
endclass
