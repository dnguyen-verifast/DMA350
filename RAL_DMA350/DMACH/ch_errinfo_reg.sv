// CH_ERRINFO - Offset 0x90 - RO - reset 0x00000000
// Channel Error Information register.
class ch_errinfo_reg extends uvm_reg;
    rand uvm_reg_field ERRINFO;
    rand uvm_reg_field STREAMERR;
    rand uvm_reg_field TRIGOUTSELERR;
    rand uvm_reg_field DESTRIGINSELERR;
    rand uvm_reg_field SRCTRIGINSELERR;
    rand uvm_reg_field CFGERR;
    rand uvm_reg_field BUSERR;

    `uvm_object_utils(ch_errinfo_reg)
    function new(string name = "ch_errinfo_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.ERRINFO         = uvm_reg_field::type_id::create("ERRINFO",, get_full_name());
        this.STREAMERR       = uvm_reg_field::type_id::create("STREAMERR",, get_full_name());
        this.TRIGOUTSELERR   = uvm_reg_field::type_id::create("TRIGOUTSELERR",, get_full_name());
        this.DESTRIGINSELERR = uvm_reg_field::type_id::create("DESTRIGINSELERR",, get_full_name());
        this.SRCTRIGINSELERR = uvm_reg_field::type_id::create("SRCTRIGINSELERR",, get_full_name());
        this.CFGERR          = uvm_reg_field::type_id::create("CFGERR",, get_full_name());
        this.BUSERR          = uvm_reg_field::type_id::create("BUSERR",, get_full_name());

        //                      parent size lsb access volatile reset has_reset is_rand indiv_access
        this.ERRINFO.configure(        this,16,16,"RO",1,16'h0,1,0,0);
        this.STREAMERR.configure(      this, 1, 7,"RO",1, 1'h0,1,0,0);
        this.TRIGOUTSELERR.configure(  this, 1, 4,"RO",1, 1'h0,1,0,0);
        this.DESTRIGINSELERR.configure(this, 1, 3,"RO",1, 1'h0,1,0,0);
        this.SRCTRIGINSELERR.configure(this, 1, 2,"RO",1, 1'h0,1,0,0);
        this.CFGERR.configure(         this, 1, 1,"RO",1, 1'h0,1,0,0);
        this.BUSERR.configure(         this, 1, 0,"RO",1, 1'h0,1,0,0);
    endfunction
endclass
