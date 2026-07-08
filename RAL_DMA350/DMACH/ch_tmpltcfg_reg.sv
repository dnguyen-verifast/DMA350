// CH_TMPLTCFG - Offset 0x40 - RW - reset 0x00000000
// Channel Template Configuration (template sizes for templated transfers).
class ch_tmpltcfg_reg extends uvm_reg;
    rand uvm_reg_field DESTMPLTSIZE;
    rand uvm_reg_field SRCTMPLTSIZE;

    `uvm_object_utils(ch_tmpltcfg_reg)
    function new(string name = "ch_tmpltcfg_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DESTMPLTSIZE = uvm_reg_field::type_id::create("DESTMPLTSIZE",, get_full_name());
        this.SRCTMPLTSIZE = uvm_reg_field::type_id::create("SRCTMPLTSIZE",, get_full_name());
        //                   parent size lsb access volatile reset has_reset is_rand indiv_access
        this.DESTMPLTSIZE.configure(this,5,16,"RW",0,5'h0,1,0,0);
        this.SRCTMPLTSIZE.configure(this,5, 8,"RW",0,5'h0,1,0,0);
    endfunction
endclass
