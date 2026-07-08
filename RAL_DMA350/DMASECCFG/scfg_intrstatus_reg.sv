// SCFG_INTRSTATUS - Offset 0x44 - RW - reset 0x00000000
// Security Configuration Interrupt Status (Secure access violation).
class scfg_intrstatus_reg extends uvm_reg;
    rand uvm_reg_field STAT_SECACCVIO;
    rand uvm_reg_field INTR_SECACCVIO;

    `uvm_object_utils(scfg_intrstatus_reg)
    function new(string name = "scfg_intrstatus_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.STAT_SECACCVIO = uvm_reg_field::type_id::create("STAT_SECACCVIO",, get_full_name());
        this.INTR_SECACCVIO = uvm_reg_field::type_id::create("INTR_SECACCVIO",, get_full_name());
        //                     parent size lsb access volatile reset has_reset is_rand indiv_access
        this.STAT_SECACCVIO.configure(this,1,16,"W1C",1,1'h0,1,0,0);
        this.INTR_SECACCVIO.configure(this,1, 0,"RO", 1,1'h0,1,0,0);
    endfunction
endclass
