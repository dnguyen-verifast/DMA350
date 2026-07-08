// CH_DESTRANSCFG - Offset 0x2C - RW - reset 0x000F0400
// Channel Destination Transfer Configuration (write-side AXI attributes).
class ch_destranscfg_reg extends uvm_reg;
    rand uvm_reg_field DESMAXBURSTLEN;
    rand uvm_reg_field DESPRIVATTR;
    rand uvm_reg_field DESNONSECATTR;
    rand uvm_reg_field DESSHAREATTR;
    rand uvm_reg_field DESMEMATTRHI;
    rand uvm_reg_field DESMEMATTRLO;

    `uvm_object_utils(ch_destranscfg_reg)
    function new(string name = "ch_destranscfg_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DESMAXBURSTLEN = uvm_reg_field::type_id::create("DESMAXBURSTLEN",, get_full_name());
        this.DESPRIVATTR    = uvm_reg_field::type_id::create("DESPRIVATTR",, get_full_name());
        this.DESNONSECATTR  = uvm_reg_field::type_id::create("DESNONSECATTR",, get_full_name());
        this.DESSHAREATTR   = uvm_reg_field::type_id::create("DESSHAREATTR",, get_full_name());
        this.DESMEMATTRHI   = uvm_reg_field::type_id::create("DESMEMATTRHI",, get_full_name());
        this.DESMEMATTRLO   = uvm_reg_field::type_id::create("DESMEMATTRLO",, get_full_name());

        //                     parent size lsb access volatile reset has_reset is_rand indiv_access
        this.DESMAXBURSTLEN.configure(this,4,16,"RW",0,4'hf,1,0,0);
        this.DESPRIVATTR.configure(   this,1,11,"RW",0,1'h0,1,0,0);
        this.DESNONSECATTR.configure( this,1,10,"RW",0,1'h1,1,0,0);
        this.DESSHAREATTR.configure(  this,2, 8,"RW",0,2'h0,1,0,0);
        this.DESMEMATTRHI.configure(  this,4, 4,"RW",0,4'h0,1,0,0);
        this.DESMEMATTRLO.configure(  this,4, 0,"RW",0,4'h0,1,0,0);
    endfunction
endclass
