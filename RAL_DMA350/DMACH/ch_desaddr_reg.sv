// CH_DESADDR - Offset 0x18 - RW - reset 0x00000000
// Channel Destination Address [31:0]. HW updates it (approximate hint) during execution.
class ch_desaddr_reg extends uvm_reg;
    rand uvm_reg_field DESADDR;

    `uvm_object_utils(ch_desaddr_reg)
    function new(string name = "ch_desaddr_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DESADDR = uvm_reg_field::type_id::create("DESADDR",, get_full_name());
        //              parent size lsb access volatile reset has_reset is_rand indiv_access
        this.DESADDR.configure(this,32,0,"RW",1,32'h0,1,0,0);
    endfunction
endclass
