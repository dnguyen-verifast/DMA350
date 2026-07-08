// CH_WRKREGVAL - Offset 0x8C - RO - reset 0x00000000
// Channel Working Register Value (internal register selected by CH_WRKREGPTR).
class ch_wrkregval_reg extends uvm_reg;
    rand uvm_reg_field WRKREGVAL;

    `uvm_object_utils(ch_wrkregval_reg)
    function new(string name = "ch_wrkregval_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.WRKREGVAL = uvm_reg_field::type_id::create("WRKREGVAL",, get_full_name());
        //                parent size lsb access volatile reset has_reset is_rand indiv_access
        this.WRKREGVAL.configure(this,32,0,"RO",1,32'h0,1,0,0);
    endfunction
endclass
