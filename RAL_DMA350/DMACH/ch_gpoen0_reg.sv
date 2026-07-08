// CH_GPOEN0 - Offset 0x58 - RW - reset 0x00000000
// Channel GPO Driving Enable mask for GPO[31:0].
class ch_gpoen0_reg extends uvm_reg;
    rand uvm_reg_field GPOEN0;

    `uvm_object_utils(ch_gpoen0_reg)
    function new(string name = "ch_gpoen0_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.GPOEN0 = uvm_reg_field::type_id::create("GPOEN0",, get_full_name());
        //             parent size lsb access volatile reset has_reset is_rand indiv_access
        this.GPOEN0.configure(this,32,0,"RW",0,32'h0,1,0,0);
    endfunction
endclass
