// PIDR2 - Offset 0xE8 - RO - reset IMPLEMENTATION DEFINED (REVISION=0x0, JEDEC=0x1, DES_1=0x3)
// Peripheral ID2.
class pidr2_reg extends uvm_reg;
    rand uvm_reg_field REVISION;
    rand uvm_reg_field JEDEC;
    rand uvm_reg_field DES_1;

    `uvm_object_utils(pidr2_reg)
    function new(string name = "pidr2_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.REVISION = uvm_reg_field::type_id::create("REVISION",, get_full_name());
        this.JEDEC    = uvm_reg_field::type_id::create("JEDEC",, get_full_name());
        this.DES_1    = uvm_reg_field::type_id::create("DES_1",, get_full_name());
        //             parent size lsb access volatile reset has_reset is_rand indiv_access
        this.REVISION.configure(this,4,4,"RO",0,4'h0,1,0,0);
        this.JEDEC.configure(   this,1,3,"RO",0,1'h1,1,0,0);
        this.DES_1.configure(   this,3,0,"RO",0,3'h3,1,0,0);
    endfunction
endclass
