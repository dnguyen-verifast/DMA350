// NSEC_CTRL - Offset 0x0C - RW - reset 0x00000000
// Non-secure control: power/debug-halt/all-channel requests + interrupt enables.
class nsec_ctrl_reg extends uvm_reg;
    rand uvm_reg_field DISMINPWR;
    rand uvm_reg_field IDLERETEN;
    rand uvm_reg_field DBGHALTEN;
    rand uvm_reg_field DBGHALTNSRO;
    rand uvm_reg_field ALLCHPAUSE;
    rand uvm_reg_field ALLCHSTOP;
    rand uvm_reg_field INTREN_ALLCHPAUSED;
    rand uvm_reg_field INTREN_ALLCHSTOPPED;
    rand uvm_reg_field INTREN_ALLCHIDLE;
    rand uvm_reg_field INTREN_ANYCHINTR;

    `uvm_object_utils(nsec_ctrl_reg)
    function new(string name = "nsec_ctrl_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DISMINPWR           = uvm_reg_field::type_id::create("DISMINPWR",, get_full_name());
        this.IDLERETEN           = uvm_reg_field::type_id::create("IDLERETEN",, get_full_name());
        this.DBGHALTEN           = uvm_reg_field::type_id::create("DBGHALTEN",, get_full_name());
        this.DBGHALTNSRO         = uvm_reg_field::type_id::create("DBGHALTNSRO",, get_full_name());
        this.ALLCHPAUSE          = uvm_reg_field::type_id::create("ALLCHPAUSE",, get_full_name());
        this.ALLCHSTOP           = uvm_reg_field::type_id::create("ALLCHSTOP",, get_full_name());
        this.INTREN_ALLCHPAUSED  = uvm_reg_field::type_id::create("INTREN_ALLCHPAUSED",, get_full_name());
        this.INTREN_ALLCHSTOPPED = uvm_reg_field::type_id::create("INTREN_ALLCHSTOPPED",, get_full_name());
        this.INTREN_ALLCHIDLE    = uvm_reg_field::type_id::create("INTREN_ALLCHIDLE",, get_full_name());
        this.INTREN_ANYCHINTR    = uvm_reg_field::type_id::create("INTREN_ANYCHINTR",, get_full_name());

        //                      parent size lsb access volatile reset has_reset is_rand indiv_access
        this.DISMINPWR.configure(          this,2,30,"RW", 0,2'h0,1,0,0);
        this.IDLERETEN.configure(          this,1,29,"RW", 0,1'h0,1,0,0);
        this.DBGHALTEN.configure(          this,1,28,"RW", 0,1'h0,1,0,0);
        this.DBGHALTNSRO.configure(        this,1,27,"RO", 0,1'h0,1,0,0);
        this.ALLCHPAUSE.configure(         this,1, 9,"W1S",0,1'h0,1,0,0);
        this.ALLCHSTOP.configure(          this,1, 8,"W1S",0,1'h0,1,0,0);
        this.INTREN_ALLCHPAUSED.configure( this,1, 3,"RW", 0,1'h0,1,0,0);
        this.INTREN_ALLCHSTOPPED.configure(this,1, 2,"RW", 0,1'h0,1,0,0);
        this.INTREN_ALLCHIDLE.configure(   this,1, 1,"RW", 0,1'h0,1,0,0);
        this.INTREN_ANYCHINTR.configure(   this,1, 0,"RW", 0,1'h0,1,0,0);
    endfunction
endclass
