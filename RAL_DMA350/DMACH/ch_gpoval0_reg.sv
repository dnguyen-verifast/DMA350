// CH_GPOVAL0 - Offset 0x60 - RW - reset 0x00000000
// Channel GPO Value for GPO[31:0].
class ch_gpoval0_reg extends uvm_reg;
    rand uvm_reg_field GPOVAL0;

    `uvm_object_utils(ch_gpoval0_reg)
    function new(string name = "ch_gpoval0_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.GPOVAL0 = uvm_reg_field::type_id::create("GPOVAL0",, get_full_name());
        //              parent size lsb access volatile reset has_reset is_rand indiv_access
        this.GPOVAL0.configure(this,32,0,"RW",0,32'h0,1,0,0);
    endfunction
endclass
