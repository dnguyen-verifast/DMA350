class ch_cmd_reg extends uvm_reg;
    rand uvm_reg_field ENABLECMD;
    rand uvm_reg_field CLEARCMD;
    rand uvm_reg_field DISABLECMD;
    rand uvm_reg_field STOPCMD;
    rand uvm_reg_field PAUSECMD;
    rand uvm_reg_field RESUMECMD;
    rand uvm_reg_field SRCSWTRIGINREQ;
    rand uvm_reg_field SRCSWTRIGINTYPE;
    rand uvm_reg_field DESSWTRIGINREQ;
    rand uvm_reg_field DESSWTRIGINTYPE;
    rand uvm_reg_field SWTRIGOUTACK;
    `uvm_object_utils(ch_cmd_reg)
    // function new (
    //    string name = "",
    //    int unsigned n_bits,  
    //    int has_coverage  
    // )
    function new(string name = "ch_cmd_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE)); 
    endfunction
    virtual function void build();
        this.ENABLECMD = uvm_reg_field::type_id::create("ENABLECMD",, get_full_name());
        this.CLEARCMD  = uvm_reg_field::type_id::create("CLEARCMD",, get_full_name());
        this.DISABLECMD = uvm_reg_field::type_id::create("DISABLECMD",, get_full_name());
        this.STOPCMD    = uvm_reg_field::type_id::create("STOPCMD",, get_full_name());
        this.PAUSECMD   = uvm_reg_field::type_id::create("PAUSECMD",, get_full_name());
        this.RESUMECMD  = uvm_reg_field::type_id::create("RESUMECMD",, get_full_name());
        this.SRCSWTRIGINREQ = uvm_reg_field::type_id::create("SRCSWTRIGINREQ",, get_full_name());
        this.SRCSWTRIGINTYPE    = uvm_reg_field::type_id::create("SRCSWTRIGINTYPE",, get_full_name());
        this.DESSWTRIGINREQ   = uvm_reg_field::type_id::create("DESSWTRIGINREQ",, get_full_name());
        this.DESSWTRIGINTYPE  = uvm_reg_field::type_id::create("DESSWTRIGINTYPE",, get_full_name());
        this.SWTRIGOUTACK = uvm_reg_field::type_id::create("SWTRIGOUTACK",, get_full_name());

        this.ENABLECMD.configure(   .parent(this),
                                    .size(1),
                                    .lsb_pos(0),
                                    .access("W1S"),
                                    .volatile(0), // volatile = 1: The field value can be changed unpredictably by the hardware/DUT (e.g., Status flags, counters, interrupt registers). UVM will not strictly complain about mismatches between the mirrored value and the bus read value.
                                                  //volatile = 0 (Default): The field value only changes when the software writes to it (e.g., Configuration registers). UVM maintains strict consistency checks between the mirror and the actual hardware.
                                    .reset(1'h0),
                                    .has_reset(1),
                                    .is_rand(0),
                                    .individually_accessible(0));
        this.CLEARCMD.configure(.parent(this),
                                .size(1),
                                .lsb_pos(1),
                                .access("W1S"),
                                .volatile(0),
                                .reset(1'h0),
                                .has_reset(1),
                                .is_rand(0),
                                .individually_accessible(0));
        this.DISABLECMD.configure(this,1,2,"W1S",0,1'h0,1,0,0);
        this.STOPCMD.configure(this,1,3,"W1S",0,1'h0,1,0,0);
        this.PAUSECMD.configure(this,1,4,"W1S",0,1'h0,1,0,0);
        this.RESUMECMD.configure(this,1,5,"W1S",0,1'h0,1,0,0);
        this.SRCSWTRIGINREQ.configure(this,1,16,"W1S",0,1'h0,1,0,0);
        this.SRCSWTRIGINTYPE.configure(this,2,17,"RW",0,1'h0,1,0,0);
        this.DESSWTRIGINREQ.configure(this,1,20,"W1S",0,1'h0,1,0,0);
        this.DESSWTRIGINTYPE.configure(this,2,21,"RW",0,1'h0,1,0,0);
        this.SWTRIGOUTACK.configure(this,1,24,"W1S",0,1'h0,1,0,0);
    endfunction
endclass
