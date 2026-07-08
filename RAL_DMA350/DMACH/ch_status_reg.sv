// CH_STATUS - Offset 0x04 - RW - reset 0x00000000
// Channel Status register: internal status of the DMA command + interrupt flags.
class ch_status_reg extends uvm_reg;
    rand uvm_reg_field STAT_TRIGOUTACKWAIT;
    rand uvm_reg_field STAT_DESTRIGINWAIT;
    rand uvm_reg_field STAT_SRCTRIGINWAIT;
    rand uvm_reg_field STAT_RESUMEWAIT;
    rand uvm_reg_field STAT_PAUSED;
    rand uvm_reg_field STAT_STOPPED;
    rand uvm_reg_field STAT_DISABLED;
    rand uvm_reg_field STAT_ERR;
    rand uvm_reg_field STAT_DONE;
    rand uvm_reg_field INTR_TRIGOUTACKWAIT;
    rand uvm_reg_field INTR_DESTRIGINWAIT;
    rand uvm_reg_field INTR_SRCTRIGINWAIT;
    rand uvm_reg_field INTR_STOPPED;
    rand uvm_reg_field INTR_DISABLED;
    rand uvm_reg_field INTR_ERR;
    rand uvm_reg_field INTR_DONE;

    `uvm_object_utils(ch_status_reg)
    function new(string name = "ch_status_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.STAT_TRIGOUTACKWAIT = uvm_reg_field::type_id::create("STAT_TRIGOUTACKWAIT",, get_full_name());
        this.STAT_DESTRIGINWAIT  = uvm_reg_field::type_id::create("STAT_DESTRIGINWAIT",, get_full_name());
        this.STAT_SRCTRIGINWAIT  = uvm_reg_field::type_id::create("STAT_SRCTRIGINWAIT",, get_full_name());
        this.STAT_RESUMEWAIT     = uvm_reg_field::type_id::create("STAT_RESUMEWAIT",, get_full_name());
        this.STAT_PAUSED         = uvm_reg_field::type_id::create("STAT_PAUSED",, get_full_name());
        this.STAT_STOPPED        = uvm_reg_field::type_id::create("STAT_STOPPED",, get_full_name());
        this.STAT_DISABLED       = uvm_reg_field::type_id::create("STAT_DISABLED",, get_full_name());
        this.STAT_ERR            = uvm_reg_field::type_id::create("STAT_ERR",, get_full_name());
        this.STAT_DONE           = uvm_reg_field::type_id::create("STAT_DONE",, get_full_name());
        this.INTR_TRIGOUTACKWAIT = uvm_reg_field::type_id::create("INTR_TRIGOUTACKWAIT",, get_full_name());
        this.INTR_DESTRIGINWAIT  = uvm_reg_field::type_id::create("INTR_DESTRIGINWAIT",, get_full_name());
        this.INTR_SRCTRIGINWAIT  = uvm_reg_field::type_id::create("INTR_SRCTRIGINWAIT",, get_full_name());
        this.INTR_STOPPED        = uvm_reg_field::type_id::create("INTR_STOPPED",, get_full_name());
        this.INTR_DISABLED       = uvm_reg_field::type_id::create("INTR_DISABLED",, get_full_name());
        this.INTR_ERR            = uvm_reg_field::type_id::create("INTR_ERR",, get_full_name());
        this.INTR_DONE           = uvm_reg_field::type_id::create("INTR_DONE",, get_full_name());

        //                       parent size lsb access volatile reset has_reset is_rand indiv_access
        this.STAT_TRIGOUTACKWAIT.configure(this,1,26,"RO", 1,1'h0,1,0,0);
        this.STAT_DESTRIGINWAIT.configure( this,1,25,"RO", 1,1'h0,1,0,0);
        this.STAT_SRCTRIGINWAIT.configure( this,1,24,"RO", 1,1'h0,1,0,0);
        this.STAT_RESUMEWAIT.configure(    this,1,21,"RO", 1,1'h0,1,0,0);
        this.STAT_PAUSED.configure(        this,1,20,"RO", 1,1'h0,1,0,0);
        this.STAT_STOPPED.configure(       this,1,19,"W1C",1,1'h0,1,0,0);
        this.STAT_DISABLED.configure(      this,1,18,"W1C",1,1'h0,1,0,0);
        this.STAT_ERR.configure(           this,1,17,"W1C",1,1'h0,1,0,0);
        this.STAT_DONE.configure(          this,1,16,"W1C",1,1'h0,1,0,0);
        this.INTR_TRIGOUTACKWAIT.configure(this,1,10,"RO", 1,1'h0,1,0,0);
        this.INTR_DESTRIGINWAIT.configure( this,1, 9,"RO", 1,1'h0,1,0,0);
        this.INTR_SRCTRIGINWAIT.configure( this,1, 8,"RO", 1,1'h0,1,0,0);
        this.INTR_STOPPED.configure(       this,1, 3,"RO", 1,1'h0,1,0,0);
        this.INTR_DISABLED.configure(      this,1, 2,"RO", 1,1'h0,1,0,0);
        this.INTR_ERR.configure(           this,1, 1,"RO", 1,1'h0,1,0,0);
        this.INTR_DONE.configure(          this,1, 0,"RO", 1,1'h0,1,0,0);
    endfunction
endclass
