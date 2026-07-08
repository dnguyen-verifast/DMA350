// CIDR3 - Offset 0xFC - RO - reset 0x000000B1
// Component ID3 (preamble).
class cidr3_reg extends uvm_reg;
    rand uvm_reg_field PRMBL_3;

    `uvm_object_utils(cidr3_reg)
    function new(string name = "cidr3_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.PRMBL_3 = uvm_reg_field::type_id::create("PRMBL_3",, get_full_name());
        //              parent size lsb access volatile reset has_reset is_rand indiv_access
        this.PRMBL_3.configure(this,8,0,"RO",0,8'hb1,1,0,0);
    endfunction
endclass
