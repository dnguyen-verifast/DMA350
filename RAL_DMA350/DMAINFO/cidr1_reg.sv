// CIDR1 - Offset 0xF4 - RO - reset 0x000000F0
// Component ID1 (component class + preamble).
class cidr1_reg extends uvm_reg;
    rand uvm_reg_field CLASS;
    rand uvm_reg_field PRMBL_1;

    `uvm_object_utils(cidr1_reg)
    function new(string name = "cidr1_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.CLASS   = uvm_reg_field::type_id::create("CLASS",, get_full_name());
        this.PRMBL_1 = uvm_reg_field::type_id::create("PRMBL_1",, get_full_name());
        //            parent size lsb access volatile reset has_reset is_rand indiv_access
        this.CLASS.configure(  this,4,4,"RO",0,4'hf,1,0,0);
        this.PRMBL_1.configure(this,4,0,"RO",0,4'h0,1,0,0);
    endfunction
endclass
