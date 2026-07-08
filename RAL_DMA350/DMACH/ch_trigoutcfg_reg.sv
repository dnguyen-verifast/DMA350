// CH_TRIGOUTCFG - Offset 0x54 - RW - reset 0x00000000
// Channel Trigger Out Configuration.
class ch_trigoutcfg_reg extends uvm_reg;
    rand uvm_reg_field TRIGOUTTYPE;
    rand uvm_reg_field TRIGOUTSEL;

    `uvm_object_utils(ch_trigoutcfg_reg)
    function new(string name = "ch_trigoutcfg_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.TRIGOUTTYPE = uvm_reg_field::type_id::create("TRIGOUTTYPE",, get_full_name());
        this.TRIGOUTSEL  = uvm_reg_field::type_id::create("TRIGOUTSEL",, get_full_name());
        //                  parent size lsb access volatile reset has_reset is_rand indiv_access
        this.TRIGOUTTYPE.configure(this,2,8,"RW",0,2'h0,1,0,0);
        this.TRIGOUTSEL.configure( this,6,0,"RW",0,6'h0,1,0,0);
    endfunction
endclass
