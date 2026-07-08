// NSEC_CHCFG - Offset 0x18 - RW - reset 0x00000000
// Non-secure Channel Configuration (privilege + channel ID) for channel in NSEC_CHPTR.
class nsec_chcfg_reg extends uvm_reg;
    rand uvm_reg_field CHPRIV;
    rand uvm_reg_field CHIDVLD;
    rand uvm_reg_field CHID;

    `uvm_object_utils(nsec_chcfg_reg)
    function new(string name = "nsec_chcfg_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.CHPRIV  = uvm_reg_field::type_id::create("CHPRIV",, get_full_name());
        this.CHIDVLD = uvm_reg_field::type_id::create("CHIDVLD",, get_full_name());
        this.CHID    = uvm_reg_field::type_id::create("CHID",, get_full_name());
        //             parent size lsb access volatile reset has_reset is_rand indiv_access
        this.CHPRIV.configure( this, 1,17,"RW",0, 1'h0,1,0,0);
        this.CHIDVLD.configure(this, 1,16,"RW",0, 1'h0,1,0,0);
        this.CHID.configure(   this,16, 0,"RW",0,16'h0,1,0,0);
    endfunction
endclass
