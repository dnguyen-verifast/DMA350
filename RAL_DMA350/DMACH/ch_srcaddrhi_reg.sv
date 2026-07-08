// CH_SRCADDRHI - Offset 0x14 - RW - reset 0x00000000
// Channel Source Address [63:32] (64-bit addressing).
class ch_srcaddrhi_reg extends uvm_reg;
    rand uvm_reg_field SRCADDRHI;

    `uvm_object_utils(ch_srcaddrhi_reg)
    function new(string name = "ch_srcaddrhi_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.SRCADDRHI = uvm_reg_field::type_id::create("SRCADDRHI",, get_full_name());
        //                parent size lsb access volatile reset has_reset is_rand indiv_access
        this.SRCADDRHI.configure(this,32,0,"RW",1,32'h0,1,0,0);
    endfunction
endclass
