// SCFG_TRIGOUTSEC0 - Offset 0x28 - RW - reset 0x00000000
// Trigger Output Security Mapping (1=Non-secure, 0=Secure). Width = NUM_TRIGGER_OUT (max 32).
// Becomes read-only after SEC_CFG_LCK.
class scfg_trigoutsec0_reg extends uvm_reg;
    rand uvm_reg_field SCFGTRIGOUTSEC0;

    `uvm_object_utils(scfg_trigoutsec0_reg)
    function new(string name = "scfg_trigoutsec0_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.SCFGTRIGOUTSEC0 = uvm_reg_field::type_id::create("SCFGTRIGOUTSEC0",, get_full_name());
        //                      parent size lsb access volatile reset has_reset is_rand indiv_access
        this.SCFGTRIGOUTSEC0.configure(this,32,0,"RW",0,32'h0,1,0,0);
    endfunction
endclass
