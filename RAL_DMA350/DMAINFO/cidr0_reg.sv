// CIDR0 - Offset 0xF0 - RO - reset 0x0000000D
// Component ID0 (preamble).
class cidr0_reg extends uvm_reg;
    rand uvm_reg_field PRMBL_0;

    `uvm_object_utils(cidr0_reg)
    function new(string name = "cidr0_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.PRMBL_0 = uvm_reg_field::type_id::create("PRMBL_0",, get_full_name());
        //              parent size lsb access volatile reset has_reset is_rand indiv_access
        this.PRMBL_0.configure(this,8,0,"RO",0,8'hd,1,0,0);
    endfunction
endclass
