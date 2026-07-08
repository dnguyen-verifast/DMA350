// CH_YADDRSTRIDE - Offset 0x34 - RW - reset 0x00000000
// Channel Y dimension address stride between lines (two's complement) for src/des.
class ch_yaddrstride_reg extends uvm_reg;
    rand uvm_reg_field DESYADDRSTRIDE;
    rand uvm_reg_field SRCYADDRSTRIDE;

    `uvm_object_utils(ch_yaddrstride_reg)
    function new(string name = "ch_yaddrstride_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DESYADDRSTRIDE = uvm_reg_field::type_id::create("DESYADDRSTRIDE",, get_full_name());
        this.SRCYADDRSTRIDE = uvm_reg_field::type_id::create("SRCYADDRSTRIDE",, get_full_name());
        //                     parent size lsb access volatile reset has_reset is_rand indiv_access
        this.DESYADDRSTRIDE.configure(this,16,16,"RW",0,16'h0,1,0,0);
        this.SRCYADDRSTRIDE.configure(this,16, 0,"RW",0,16'h0,1,0,0);
    endfunction
endclass
