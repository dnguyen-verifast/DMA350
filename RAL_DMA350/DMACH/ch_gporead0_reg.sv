// CH_GPOREAD0 - Offset 0x80 - RO - reset 0x00000000
// Channel GPO Read Value for GPO[31:0] (actual port value).
class ch_gporead0_reg extends uvm_reg;
    rand uvm_reg_field GPOREAD0;

    `uvm_object_utils(ch_gporead0_reg)
    function new(string name = "ch_gporead0_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.GPOREAD0 = uvm_reg_field::type_id::create("GPOREAD0",, get_full_name());
        //               parent size lsb access volatile reset has_reset is_rand indiv_access
        this.GPOREAD0.configure(this,32,0,"RO",1,32'h0,1,0,0);
    endfunction
endclass
