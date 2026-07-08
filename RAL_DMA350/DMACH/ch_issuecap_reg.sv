// CH_ISSUECAP - Offset 0xE8 - RW - reset IMPLEMENTATION DEFINED (ISSUECAP default 0x7)
// Channel issuing capability threshold.
class ch_issuecap_reg extends uvm_reg;
    rand uvm_reg_field ISSUECAP;

    `uvm_object_utils(ch_issuecap_reg)
    function new(string name = "ch_issuecap_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.ISSUECAP = uvm_reg_field::type_id::create("ISSUECAP",, get_full_name());
        //               parent size lsb access volatile reset has_reset is_rand indiv_access
        this.ISSUECAP.configure(this,3,0,"RW",0,3'h7,1,0,0);
    endfunction
endclass
