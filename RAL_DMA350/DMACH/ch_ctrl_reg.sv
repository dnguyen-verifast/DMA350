// CH_CTRL - Offset 0x0C - RW - reset 0x00200200 (DONETYPE=0x1, XTYPE=0x1)
// Channel Control register: transfer type and resources for the current command.
class ch_ctrl_reg extends uvm_reg;
    rand uvm_reg_field USESTREAM;
    rand uvm_reg_field USEGPO;
    rand uvm_reg_field USETRIGOUT;
    rand uvm_reg_field USEDESTRIGIN;
    rand uvm_reg_field USESRCTRIGIN;
    rand uvm_reg_field DONEPAUSEEN;
    rand uvm_reg_field DONETYPE;
    rand uvm_reg_field REGRELOADTYPE;
    rand uvm_reg_field YTYPE;
    rand uvm_reg_field XTYPE;
    rand uvm_reg_field CHPRIO;
    rand uvm_reg_field TRANSIZE;

    `uvm_object_utils(ch_ctrl_reg)
    function new(string name = "ch_ctrl_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.USESTREAM     = uvm_reg_field::type_id::create("USESTREAM",, get_full_name());
        this.USEGPO        = uvm_reg_field::type_id::create("USEGPO",, get_full_name());
        this.USETRIGOUT    = uvm_reg_field::type_id::create("USETRIGOUT",, get_full_name());
        this.USEDESTRIGIN  = uvm_reg_field::type_id::create("USEDESTRIGIN",, get_full_name());
        this.USESRCTRIGIN  = uvm_reg_field::type_id::create("USESRCTRIGIN",, get_full_name());
        this.DONEPAUSEEN   = uvm_reg_field::type_id::create("DONEPAUSEEN",, get_full_name());
        this.DONETYPE      = uvm_reg_field::type_id::create("DONETYPE",, get_full_name());
        this.REGRELOADTYPE = uvm_reg_field::type_id::create("REGRELOADTYPE",, get_full_name());
        this.YTYPE         = uvm_reg_field::type_id::create("YTYPE",, get_full_name());
        this.XTYPE         = uvm_reg_field::type_id::create("XTYPE",, get_full_name());
        this.CHPRIO        = uvm_reg_field::type_id::create("CHPRIO",, get_full_name());
        this.TRANSIZE      = uvm_reg_field::type_id::create("TRANSIZE",, get_full_name());

        //                parent size lsb access volatile reset has_reset is_rand indiv_access
        this.USESTREAM.configure(    this,1,29,"RW",0,1'h0,1,0,0);
        this.USEGPO.configure(       this,1,28,"RW",0,1'h0,1,0,0);
        this.USETRIGOUT.configure(   this,1,27,"RW",0,1'h0,1,0,0);
        this.USEDESTRIGIN.configure( this,1,26,"RW",0,1'h0,1,0,0);
        this.USESRCTRIGIN.configure( this,1,25,"RW",0,1'h0,1,0,0);
        this.DONEPAUSEEN.configure(  this,1,24,"RW",0,1'h0,1,0,0);
        this.DONETYPE.configure(     this,3,21,"RW",0,3'h1,1,0,0);
        this.REGRELOADTYPE.configure(this,3,18,"RW",0,3'h0,1,0,0);
        this.YTYPE.configure(        this,3,12,"RW",0,3'h0,1,0,0);
        this.XTYPE.configure(        this,3, 9,"RW",0,3'h1,1,0,0);
        this.CHPRIO.configure(       this,4, 4,"RW",0,4'h0,1,0,0);
        this.TRANSIZE.configure(     this,3, 0,"RW",0,3'h0,1,0,0);
    endfunction
endclass
