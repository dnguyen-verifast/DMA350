// PIDR0 - Offset 0xE0 - RO - reset IMPLEMENTATION DEFINED (PART_0 = 0xA0)
// Peripheral ID0.
class pidr0_reg extends uvm_reg;
    rand uvm_reg_field PART_0;

    `uvm_object_utils(pidr0_reg)
    function new(string name = "pidr0_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.PART_0 = uvm_reg_field::type_id::create("PART_0",, get_full_name());
        //             parent size lsb access volatile reset has_reset is_rand indiv_access
        this.PART_0.configure(this,8,0,"RO",0,8'hA0,1,0,0);
    endfunction
endclass
