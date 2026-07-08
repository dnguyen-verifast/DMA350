// CH_INTREN - Offset 0x08 - RW - reset 0x00000000
// Channel Interrupt Enable register.
class ch_intren_reg extends uvm_reg;
    rand uvm_reg_field INTREN_TRIGOUTACKWAIT;
    rand uvm_reg_field INTREN_DESTRIGINWAIT;
    rand uvm_reg_field INTREN_SRCTRIGINWAIT;
    rand uvm_reg_field INTREN_STOPPED;
    rand uvm_reg_field INTREN_DISABLED;
    rand uvm_reg_field INTREN_ERR;
    rand uvm_reg_field INTREN_DONE;

    `uvm_object_utils(ch_intren_reg)
    function new(string name = "ch_intren_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.INTREN_TRIGOUTACKWAIT = uvm_reg_field::type_id::create("INTREN_TRIGOUTACKWAIT",, get_full_name());
        this.INTREN_DESTRIGINWAIT  = uvm_reg_field::type_id::create("INTREN_DESTRIGINWAIT",, get_full_name());
        this.INTREN_SRCTRIGINWAIT  = uvm_reg_field::type_id::create("INTREN_SRCTRIGINWAIT",, get_full_name());
        this.INTREN_STOPPED        = uvm_reg_field::type_id::create("INTREN_STOPPED",, get_full_name());
        this.INTREN_DISABLED       = uvm_reg_field::type_id::create("INTREN_DISABLED",, get_full_name());
        this.INTREN_ERR            = uvm_reg_field::type_id::create("INTREN_ERR",, get_full_name());
        this.INTREN_DONE           = uvm_reg_field::type_id::create("INTREN_DONE",, get_full_name());

        //                      parent size lsb access volatile reset has_reset is_rand indiv_access
        this.INTREN_TRIGOUTACKWAIT.configure(this,1,10,"RW",0,1'h0,1,0,0);
        this.INTREN_DESTRIGINWAIT.configure( this,1, 9,"RW",0,1'h0,1,0,0);
        this.INTREN_SRCTRIGINWAIT.configure( this,1, 8,"RW",0,1'h0,1,0,0);
        this.INTREN_STOPPED.configure(       this,1, 3,"RW",0,1'h0,1,0,0);
        this.INTREN_DISABLED.configure(      this,1, 2,"RW",0,1'h0,1,0,0);
        this.INTREN_ERR.configure(           this,1, 1,"RW",0,1'h0,1,0,0);
        this.INTREN_DONE.configure(          this,1, 0,"RW",0,1'h0,1,0,0);
    endfunction
endclass
