// CH_FILLVAL - Offset 0x38 - RW - reset 0x00000000
// Channel Fill Pattern Value used when XTYPE/YTYPE = fill.
class ch_fillval_reg extends uvm_reg;
    rand uvm_reg_field FILLVAL;

    `uvm_object_utils(ch_fillval_reg)
    function new(string name = "ch_fillval_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.FILLVAL = uvm_reg_field::type_id::create("FILLVAL",, get_full_name());
        //              parent size lsb access volatile reset has_reset is_rand indiv_access
        this.FILLVAL.configure(this,32,0,"RW",0,32'h0,1,0,0);
    endfunction
endclass
