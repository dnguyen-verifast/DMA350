// CH_STREAMINTCFG - Offset 0x68 - RW - reset 0x00000000
// Channel Stream Interface Configuration.
class ch_streamintcfg_reg extends uvm_reg;
    rand uvm_reg_field STREAMTYPE;

    `uvm_object_utils(ch_streamintcfg_reg)
    function new(string name = "ch_streamintcfg_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.STREAMTYPE = uvm_reg_field::type_id::create("STREAMTYPE",, get_full_name());
        //                 parent size lsb access volatile reset has_reset is_rand indiv_access
        this.STREAMTYPE.configure(this,2,9,"RW",0,2'h0,1,0,0);
    endfunction
endclass
