// PIDR3 - Offset 0xEC - RO - reset 0x00000000
// Peripheral ID3 (REVAND + CMOD).
class pidr3_reg extends uvm_reg;
    rand uvm_reg_field REVAND;
    rand uvm_reg_field CMOD;

    `uvm_object_utils(pidr3_reg)
    function new(string name = "pidr3_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.REVAND = uvm_reg_field::type_id::create("REVAND",, get_full_name());
        this.CMOD   = uvm_reg_field::type_id::create("CMOD",, get_full_name());
        //            parent size lsb access volatile reset has_reset is_rand indiv_access
        this.REVAND.configure(this,4,4,"RO",0,4'h0,1,0,0);
        this.CMOD.configure(  this,4,0,"RO",0,4'h0,1,0,0);
    endfunction
endclass
