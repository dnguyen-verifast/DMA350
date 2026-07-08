// SEC_STATUS - Offset 0x08 - RW - reset 0x00000000
// Secure overall channel status + interrupt status.
class sec_status_reg extends uvm_reg;
    rand uvm_reg_field STAT_ALLCHPAUSED;
    rand uvm_reg_field STAT_ALLCHSTOPPED;
    rand uvm_reg_field STAT_ALLCHIDLE;
    rand uvm_reg_field INTR_ALLCHPAUSED;
    rand uvm_reg_field INTR_ALLCHSTOPPED;
    rand uvm_reg_field INTR_ALLCHIDLE;
    rand uvm_reg_field INTR_ANYCHINTR;

    `uvm_object_utils(sec_status_reg)
    function new(string name = "sec_status_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.STAT_ALLCHPAUSED  = uvm_reg_field::type_id::create("STAT_ALLCHPAUSED",, get_full_name());
        this.STAT_ALLCHSTOPPED = uvm_reg_field::type_id::create("STAT_ALLCHSTOPPED",, get_full_name());
        this.STAT_ALLCHIDLE    = uvm_reg_field::type_id::create("STAT_ALLCHIDLE",, get_full_name());
        this.INTR_ALLCHPAUSED  = uvm_reg_field::type_id::create("INTR_ALLCHPAUSED",, get_full_name());
        this.INTR_ALLCHSTOPPED = uvm_reg_field::type_id::create("INTR_ALLCHSTOPPED",, get_full_name());
        this.INTR_ALLCHIDLE    = uvm_reg_field::type_id::create("INTR_ALLCHIDLE",, get_full_name());
        this.INTR_ANYCHINTR    = uvm_reg_field::type_id::create("INTR_ANYCHINTR",, get_full_name());

        //                      parent size lsb access volatile reset has_reset is_rand indiv_access
        this.STAT_ALLCHPAUSED.configure( this,1,19,"W1C",1,1'h0,1,0,0);
        this.STAT_ALLCHSTOPPED.configure(this,1,18,"W1C",1,1'h0,1,0,0);
        this.STAT_ALLCHIDLE.configure(   this,1,17,"W1C",1,1'h0,1,0,0);
        this.INTR_ALLCHPAUSED.configure( this,1, 3,"RO", 1,1'h0,1,0,0);
        this.INTR_ALLCHSTOPPED.configure(this,1, 2,"RO", 1,1'h0,1,0,0);
        this.INTR_ALLCHIDLE.configure(   this,1, 1,"RO", 1,1'h0,1,0,0);
        this.INTR_ANYCHINTR.configure(   this,1, 0,"RO", 1,1'h0,1,0,0);
    endfunction
endclass
