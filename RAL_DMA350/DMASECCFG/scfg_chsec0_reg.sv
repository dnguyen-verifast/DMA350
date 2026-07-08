// SCFG_CHSEC0 - Offset 0x00 - RW - reset 0x00000000
// Channel Security Mapping for channel 0..NUM_CHANNELS-1 (1=Non-secure, 0=Secure).
// NOTE: field width = NUM_CHANNELS (max 8); modeled as 8 bits. Becomes read-only after SEC_CFG_LCK.
class scfg_chsec0_reg extends uvm_reg;
    rand uvm_reg_field SCFGCHSEC0;

    `uvm_object_utils(scfg_chsec0_reg)
    function new(string name = "scfg_chsec0_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.SCFGCHSEC0 = uvm_reg_field::type_id::create("SCFGCHSEC0",, get_full_name());
        //                 parent size lsb access volatile reset has_reset is_rand indiv_access
        this.SCFGCHSEC0.configure(this,8,0,"RW",0,8'h0,1,0,0);
    endfunction
endclass
