// CH_DESADDRHI - Offset 0x1C - RW - reset 0x00000000
// Channel Destination Address [63:32] (64-bit addressing).
class ch_desaddrhi_reg extends uvm_reg;
    rand uvm_reg_field DESADDRHI;

    `uvm_object_utils(ch_desaddrhi_reg)
    function new(string name = "ch_desaddrhi_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DESADDRHI = uvm_reg_field::type_id::create("DESADDRHI",, get_full_name());
        //                parent size lsb access volatile reset has_reset is_rand indiv_access
        this.DESADDRHI.configure(this,32,0,"RW",1,32'h0,1,0,0);
    endfunction
endclass
