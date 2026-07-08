// SCFG_TRIGINSEC0 - Offset 0x08 - RW - reset 0x00000000
// Trigger Input Security Mapping (1=Non-secure, 0=Secure). Width = NUM_TRIGGER_IN (max 32).
// Becomes read-only after SEC_CFG_LCK.
class scfg_triginsec0_reg extends uvm_reg;
    rand uvm_reg_field SCFGTRIGINSEC0;

    `uvm_object_utils(scfg_triginsec0_reg)
    function new(string name = "scfg_triginsec0_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.SCFGTRIGINSEC0 = uvm_reg_field::type_id::create("SCFGTRIGINSEC0",, get_full_name());
        //                     parent size lsb access volatile reset has_reset is_rand indiv_access
        this.SCFGTRIGINSEC0.configure(this,32,0,"RW",0,32'h0,1,0,0);
    endfunction
endclass
