// CH_AUTOCFG - Offset 0x74 - RW - reset 0x00000000
// Channel Automatic Command Restart Configuration.
class ch_autocfg_reg extends uvm_reg;
    rand uvm_reg_field CMDRESTARTINFEN;
    rand uvm_reg_field CMDRESTARTCNT;

    `uvm_object_utils(ch_autocfg_reg)
    function new(string name = "ch_autocfg_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.CMDRESTARTINFEN = uvm_reg_field::type_id::create("CMDRESTARTINFEN",, get_full_name());
        this.CMDRESTARTCNT   = uvm_reg_field::type_id::create("CMDRESTARTCNT",, get_full_name());
        //                      parent size lsb access volatile reset has_reset is_rand indiv_access
        this.CMDRESTARTINFEN.configure(this, 1,16,"RW",0, 1'h0,1,0,0);
        this.CMDRESTARTCNT.configure(  this,16, 0,"RW",0,16'h0,1,0,0);
    endfunction
endclass
