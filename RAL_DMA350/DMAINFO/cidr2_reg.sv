// CIDR2 - Offset 0xF8 - RO - reset 0x00000005
// Component ID2 (preamble).
class cidr2_reg extends uvm_reg;
    rand uvm_reg_field PRMBL_2;

    `uvm_object_utils(cidr2_reg)
    function new(string name = "cidr2_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.PRMBL_2 = uvm_reg_field::type_id::create("PRMBL_2",, get_full_name());
        //              parent size lsb access volatile reset has_reset is_rand indiv_access
        this.PRMBL_2.configure(this,8,0,"RO",0,8'h5,1,0,0);
    endfunction
endclass
