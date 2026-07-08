// CH_LINKADDRHI - Offset 0x7C - RW - reset 0x00000000
// Channel Link Address [63:32] (64-bit addressing).
class ch_linkaddrhi_reg extends uvm_reg;
    rand uvm_reg_field LINKADDRHI;

    `uvm_object_utils(ch_linkaddrhi_reg)
    function new(string name = "ch_linkaddrhi_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.LINKADDRHI = uvm_reg_field::type_id::create("LINKADDRHI",, get_full_name());
        //                 parent size lsb access volatile reset has_reset is_rand indiv_access
        this.LINKADDRHI.configure(this,32,0,"RW",0,32'h0,1,0,0);
    endfunction
endclass
