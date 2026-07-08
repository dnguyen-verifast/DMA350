// CH_XSIZE - Offset 0x20 - RW - reset 0x00000000
// Channel X dimension size, lower bits [15:0] for source and destination.
class ch_xsize_reg extends uvm_reg;
    rand uvm_reg_field DESXSIZE;
    rand uvm_reg_field SRCXSIZE;

    `uvm_object_utils(ch_xsize_reg)
    function new(string name = "ch_xsize_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DESXSIZE = uvm_reg_field::type_id::create("DESXSIZE",, get_full_name());
        this.SRCXSIZE = uvm_reg_field::type_id::create("SRCXSIZE",, get_full_name());
        //               parent size lsb access volatile reset has_reset is_rand indiv_access
        this.DESXSIZE.configure(this,16,16,"RW",1,16'h0,1,0,0);
        this.SRCXSIZE.configure(this,16, 0,"RW",1,16'h0,1,0,0);
    endfunction
endclass
