// CH_SRCTRANSCFG - Offset 0x28 - RW - reset 0x000F0400
// Channel Source Transfer Configuration (read-side AXI attributes).
class ch_srctranscfg_reg extends uvm_reg;
    rand uvm_reg_field SRCMAXBURSTLEN;
    rand uvm_reg_field SRCPRIVATTR;
    rand uvm_reg_field SRCNONSECATTR;
    rand uvm_reg_field SRCSHAREATTR;
    rand uvm_reg_field SRCMEMATTRHI;
    rand uvm_reg_field SRCMEMATTRLO;

    `uvm_object_utils(ch_srctranscfg_reg)
    function new(string name = "ch_srctranscfg_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.SRCMAXBURSTLEN = uvm_reg_field::type_id::create("SRCMAXBURSTLEN",, get_full_name());
        this.SRCPRIVATTR    = uvm_reg_field::type_id::create("SRCPRIVATTR",, get_full_name());
        this.SRCNONSECATTR  = uvm_reg_field::type_id::create("SRCNONSECATTR",, get_full_name());
        this.SRCSHAREATTR   = uvm_reg_field::type_id::create("SRCSHAREATTR",, get_full_name());
        this.SRCMEMATTRHI   = uvm_reg_field::type_id::create("SRCMEMATTRHI",, get_full_name());
        this.SRCMEMATTRLO   = uvm_reg_field::type_id::create("SRCMEMATTRLO",, get_full_name());

        //                     parent size lsb access volatile reset has_reset is_rand indiv_access
        this.SRCMAXBURSTLEN.configure(this,4,16,"RW",0,4'hf,1,0,0);
        this.SRCPRIVATTR.configure(   this,1,11,"RW",0,1'h0,1,0,0);
        this.SRCNONSECATTR.configure( this,1,10,"RW",0,1'h1,1,0,0);
        this.SRCSHAREATTR.configure(  this,2, 8,"RW",0,2'h0,1,0,0);
        this.SRCMEMATTRHI.configure(  this,4, 4,"RW",0,4'h0,1,0,0);
        this.SRCMEMATTRLO.configure(  this,4, 0,"RW",0,4'h0,1,0,0);
    endfunction
endclass
