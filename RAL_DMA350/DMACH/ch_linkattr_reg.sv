// CH_LINKATTR - Offset 0x70 - RW - reset 0x00000000
// Channel Link Address Memory Attributes (command-link read transfers).
class ch_linkattr_reg extends uvm_reg;
    rand uvm_reg_field LINKSHAREATTR;
    rand uvm_reg_field LINKMEMATTRHI;
    rand uvm_reg_field LINKMEMATTRLO;

    `uvm_object_utils(ch_linkattr_reg)
    function new(string name = "ch_linkattr_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.LINKSHAREATTR = uvm_reg_field::type_id::create("LINKSHAREATTR",, get_full_name());
        this.LINKMEMATTRHI = uvm_reg_field::type_id::create("LINKMEMATTRHI",, get_full_name());
        this.LINKMEMATTRLO = uvm_reg_field::type_id::create("LINKMEMATTRLO",, get_full_name());

        //                    parent size lsb access volatile reset has_reset is_rand indiv_access
        this.LINKSHAREATTR.configure(this,2,8,"RW",0,2'h0,1,0,0);
        this.LINKMEMATTRHI.configure(this,4,4,"RW",0,4'h0,1,0,0);
        this.LINKMEMATTRLO.configure(this,4,0,"RW",0,4'h0,1,0,0);
    endfunction
endclass
