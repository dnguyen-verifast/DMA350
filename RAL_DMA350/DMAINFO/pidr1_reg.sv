// PIDR1 - Offset 0xE4 - RO - reset IMPLEMENTATION DEFINED (DES_0=0xb, PART_1=0x3)
// Peripheral ID1.
class pidr1_reg extends uvm_reg;
    rand uvm_reg_field DES_0;
    rand uvm_reg_field PART_1;

    `uvm_object_utils(pidr1_reg)
    function new(string name = "pidr1_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DES_0  = uvm_reg_field::type_id::create("DES_0",, get_full_name());
        this.PART_1 = uvm_reg_field::type_id::create("PART_1",, get_full_name());
        //            parent size lsb access volatile reset has_reset is_rand indiv_access
        this.DES_0.configure( this,4,4,"RO",0,4'hb,1,0,0);
        this.PART_1.configure(this,4,0,"RO",0,4'h3,1,0,0);
    endfunction
endclass
