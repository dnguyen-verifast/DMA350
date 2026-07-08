// CH_LINKADDR - Offset 0x78 - RW - reset 0x00000000
// Channel Link Address [31:2] + LINKADDREN[0]. Bit[1] is reserved.
class ch_linkaddr_reg extends uvm_reg;
    rand uvm_reg_field LINKADDR;
    rand uvm_reg_field LINKADDREN;

    `uvm_object_utils(ch_linkaddr_reg)
    function new(string name = "ch_linkaddr_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.LINKADDR   = uvm_reg_field::type_id::create("LINKADDR",, get_full_name());
        this.LINKADDREN = uvm_reg_field::type_id::create("LINKADDREN",, get_full_name());
        //                 parent size lsb access volatile reset has_reset is_rand indiv_access
        this.LINKADDR.configure(  this,30,2,"RW",0,30'h0,1,0,0);
        this.LINKADDREN.configure(this, 1,0,"RW",0, 1'h0,1,0,0);
    endfunction
endclass
