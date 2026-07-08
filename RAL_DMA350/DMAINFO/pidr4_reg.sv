// PIDR4 - Offset 0xD0 - RO - reset IMPLEMENTATION DEFINED
// Peripheral ID4. SIZE = ceil(NUM_CHANNELS/16) (parameter dependent); DES_2 = JEP106 cont. = 0x4.
class pidr4_reg extends uvm_reg;
    rand uvm_reg_field SIZE;
    rand uvm_reg_field DES_2;

    `uvm_object_utils(pidr4_reg)
    function new(string name = "pidr4_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.SIZE  = uvm_reg_field::type_id::create("SIZE",, get_full_name());
        this.DES_2 = uvm_reg_field::type_id::create("DES_2",, get_full_name());
        //            parent size lsb access volatile reset has_reset is_rand indiv_access
        this.SIZE.configure( this,4,4,"RO",0,4'h0,1,0,0);
        this.DES_2.configure(this,4,0,"RO",0,4'h4,1,0,0);
    endfunction
endclass
