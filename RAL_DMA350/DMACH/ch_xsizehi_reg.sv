// CH_XSIZEHI - Offset 0x24 - RW - reset 0x00000000
// Channel X dimension size, high bits [31:16] for source and destination.
class ch_xsizehi_reg extends uvm_reg;
    rand uvm_reg_field DESXSIZEHI;
    rand uvm_reg_field SRCXSIZEHI;

    `uvm_object_utils(ch_xsizehi_reg)
    function new(string name = "ch_xsizehi_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DESXSIZEHI = uvm_reg_field::type_id::create("DESXSIZEHI",, get_full_name());
        this.SRCXSIZEHI = uvm_reg_field::type_id::create("SRCXSIZEHI",, get_full_name());
        //                 parent size lsb access volatile reset has_reset is_rand indiv_access
        this.DESXSIZEHI.configure(this,16,16,"RW",1,16'h0,1,0,0);
        this.SRCXSIZEHI.configure(this,16, 0,"RW",1,16'h0,1,0,0);
    endfunction
endclass
