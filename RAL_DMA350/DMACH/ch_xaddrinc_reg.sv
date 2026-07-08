// CH_XADDRINC - Offset 0x30 - RW - reset 0x00000000
// Channel X dimension address increments (two's complement) for src/des.
class ch_xaddrinc_reg extends uvm_reg;
    rand uvm_reg_field DESXADDRINC;
    rand uvm_reg_field SRCXADDRINC;

    `uvm_object_utils(ch_xaddrinc_reg)
    function new(string name = "ch_xaddrinc_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DESXADDRINC = uvm_reg_field::type_id::create("DESXADDRINC",, get_full_name());
        this.SRCXADDRINC = uvm_reg_field::type_id::create("SRCXADDRINC",, get_full_name());
        //                  parent size lsb access volatile reset has_reset is_rand indiv_access
        this.DESXADDRINC.configure(this,16,16,"RW",0,16'h0,1,0,0);
        this.SRCXADDRINC.configure(this,16, 0,"RW",0,16'h0,1,0,0);
    endfunction
endclass
