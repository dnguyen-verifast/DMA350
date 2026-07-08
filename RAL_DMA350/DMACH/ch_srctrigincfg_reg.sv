// CH_SRCTRIGINCFG - Offset 0x4C - RW - reset 0x00000000
// Channel Source Trigger In Configuration.
class ch_srctrigincfg_reg extends uvm_reg;
    rand uvm_reg_field SRCTRIGINBLKSIZE;
    rand uvm_reg_field SRCTRIGINMODE;
    rand uvm_reg_field SRCTRIGINTYPE;
    rand uvm_reg_field SRCTRIGINSEL;

    `uvm_object_utils(ch_srctrigincfg_reg)
    function new(string name = "ch_srctrigincfg_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.SRCTRIGINBLKSIZE = uvm_reg_field::type_id::create("SRCTRIGINBLKSIZE",, get_full_name());
        this.SRCTRIGINMODE    = uvm_reg_field::type_id::create("SRCTRIGINMODE",, get_full_name());
        this.SRCTRIGINTYPE    = uvm_reg_field::type_id::create("SRCTRIGINTYPE",, get_full_name());
        this.SRCTRIGINSEL     = uvm_reg_field::type_id::create("SRCTRIGINSEL",, get_full_name());

        //                       parent size lsb access volatile reset has_reset is_rand indiv_access
        this.SRCTRIGINBLKSIZE.configure(this,8,16,"RW",0,8'h0,1,0,0);
        this.SRCTRIGINMODE.configure(   this,2,10,"RW",0,2'h0,1,0,0);
        this.SRCTRIGINTYPE.configure(   this,2, 8,"RW",0,2'h0,1,0,0);
        this.SRCTRIGINSEL.configure(    this,8, 0,"RW",0,8'h0,1,0,0);
    endfunction
endclass
