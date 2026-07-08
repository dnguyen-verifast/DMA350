// CH_YSIZE - Offset 0x3C - RW - reset 0x00000000
// Channel Y dimension size (number of lines) for source and destination.
class ch_ysize_reg extends uvm_reg;
    rand uvm_reg_field DESYSIZE;
    rand uvm_reg_field SRCYSIZE;

    `uvm_object_utils(ch_ysize_reg)
    function new(string name = "ch_ysize_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DESYSIZE = uvm_reg_field::type_id::create("DESYSIZE",, get_full_name());
        this.SRCYSIZE = uvm_reg_field::type_id::create("SRCYSIZE",, get_full_name());
        //               parent size lsb access volatile reset has_reset is_rand indiv_access
        this.DESYSIZE.configure(this,16,16,"RW",1,16'h0,1,0,0);
        this.SRCYSIZE.configure(this,16, 0,"RW",1,16'h0,1,0,0);
    endfunction
endclass
