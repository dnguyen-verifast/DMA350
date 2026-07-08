// CH_DESTRIGINCFG - Offset 0x50 - RW - reset 0x00000000
// Channel Destination Trigger In Configuration.
class ch_destrigincfg_reg extends uvm_reg;
    rand uvm_reg_field DESTRIGINBLKSIZE;
    rand uvm_reg_field DESTRIGINMODE;
    rand uvm_reg_field DESTRIGINTYPE;
    rand uvm_reg_field DESTRIGINSEL;

    `uvm_object_utils(ch_destrigincfg_reg)
    function new(string name = "ch_destrigincfg_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DESTRIGINBLKSIZE = uvm_reg_field::type_id::create("DESTRIGINBLKSIZE",, get_full_name());
        this.DESTRIGINMODE    = uvm_reg_field::type_id::create("DESTRIGINMODE",, get_full_name());
        this.DESTRIGINTYPE    = uvm_reg_field::type_id::create("DESTRIGINTYPE",, get_full_name());
        this.DESTRIGINSEL     = uvm_reg_field::type_id::create("DESTRIGINSEL",, get_full_name());

        //                       parent size lsb access volatile reset has_reset is_rand indiv_access
        this.DESTRIGINBLKSIZE.configure(this,8,16,"RW",0,8'h0,1,0,0);
        this.DESTRIGINMODE.configure(   this,2,10,"RW",0,2'h0,1,0,0);
        this.DESTRIGINTYPE.configure(   this,2, 8,"RW",0,2'h0,1,0,0);
        this.DESTRIGINSEL.configure(    this,8, 0,"RW",0,8'h0,1,0,0);
    endfunction
endclass
