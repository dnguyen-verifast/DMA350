// CH_BUILDCFG1 - Offset 0xFC - RO - reset IMPLEMENTATION DEFINED
// Channel Build Configuration and Capability register 1.
// NOTE: GPO_WIDTH and several HAS_* bits are config-parameter dependent. The reset values
//       below use the documented fixed defaults (HAS_WRKREG/HAS_AUTO/HAS_CMDLINK/HAS_TRIGSEL/
//       HAS_TRIG/HAS_XSIZEHI = 1) and 0 for the parameter-dependent ones.
class ch_buildcfg1_reg extends uvm_reg;
    rand uvm_reg_field GPO_WIDTH;
    rand uvm_reg_field HAS_GPOSEL;
    rand uvm_reg_field HAS_STREAMSEL;
    rand uvm_reg_field HAS_STREAM;
    rand uvm_reg_field HAS_WRKREG;
    rand uvm_reg_field HAS_AUTO;
    rand uvm_reg_field HAS_CMDLINK;
    rand uvm_reg_field HAS_TRIGSEL;
    rand uvm_reg_field HAS_TRIGOUT;
    rand uvm_reg_field HAS_TRIGIN;
    rand uvm_reg_field HAS_TRIG;
    rand uvm_reg_field HAS_TMPLT;
    rand uvm_reg_field HAS_2D;
    rand uvm_reg_field HAS_WRAP;
    rand uvm_reg_field HAS_XSIZEHI;

    `uvm_object_utils(ch_buildcfg1_reg)
    function new(string name = "ch_buildcfg1_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.GPO_WIDTH     = uvm_reg_field::type_id::create("GPO_WIDTH",, get_full_name());
        this.HAS_GPOSEL    = uvm_reg_field::type_id::create("HAS_GPOSEL",, get_full_name());
        this.HAS_STREAMSEL = uvm_reg_field::type_id::create("HAS_STREAMSEL",, get_full_name());
        this.HAS_STREAM    = uvm_reg_field::type_id::create("HAS_STREAM",, get_full_name());
        this.HAS_WRKREG    = uvm_reg_field::type_id::create("HAS_WRKREG",, get_full_name());
        this.HAS_AUTO      = uvm_reg_field::type_id::create("HAS_AUTO",, get_full_name());
        this.HAS_CMDLINK   = uvm_reg_field::type_id::create("HAS_CMDLINK",, get_full_name());
        this.HAS_TRIGSEL   = uvm_reg_field::type_id::create("HAS_TRIGSEL",, get_full_name());
        this.HAS_TRIGOUT   = uvm_reg_field::type_id::create("HAS_TRIGOUT",, get_full_name());
        this.HAS_TRIGIN    = uvm_reg_field::type_id::create("HAS_TRIGIN",, get_full_name());
        this.HAS_TRIG      = uvm_reg_field::type_id::create("HAS_TRIG",, get_full_name());
        this.HAS_TMPLT     = uvm_reg_field::type_id::create("HAS_TMPLT",, get_full_name());
        this.HAS_2D        = uvm_reg_field::type_id::create("HAS_2D",, get_full_name());
        this.HAS_WRAP      = uvm_reg_field::type_id::create("HAS_WRAP",, get_full_name());
        this.HAS_XSIZEHI   = uvm_reg_field::type_id::create("HAS_XSIZEHI",, get_full_name());

        //                    parent size lsb access volatile reset has_reset is_rand indiv_access
        this.GPO_WIDTH.configure(    this,7,19,"RO",0,7'h0,1,0,0);
        this.HAS_GPOSEL.configure(   this,1,18,"RO",0,1'h0,1,0,0);
        this.HAS_STREAMSEL.configure(this,1,12,"RO",0,1'h0,1,0,0);
        this.HAS_STREAM.configure(   this,1,11,"RO",0,1'h0,1,0,0);
        this.HAS_WRKREG.configure(   this,1,10,"RO",0,1'h1,1,0,0);
        this.HAS_AUTO.configure(     this,1, 9,"RO",0,1'h1,1,0,0);
        this.HAS_CMDLINK.configure(  this,1, 8,"RO",0,1'h1,1,0,0);
        this.HAS_TRIGSEL.configure(  this,1, 7,"RO",0,1'h1,1,0,0);
        this.HAS_TRIGOUT.configure(  this,1, 6,"RO",0,1'h0,1,0,0);
        this.HAS_TRIGIN.configure(   this,1, 5,"RO",0,1'h0,1,0,0);
        this.HAS_TRIG.configure(     this,1, 4,"RO",0,1'h1,1,0,0);
        this.HAS_TMPLT.configure(    this,1, 3,"RO",0,1'h0,1,0,0);
        this.HAS_2D.configure(       this,1, 2,"RO",0,1'h0,1,0,0);
        this.HAS_WRAP.configure(     this,1, 1,"RO",0,1'h0,1,0,0);
        this.HAS_XSIZEHI.configure(  this,1, 0,"RO",0,1'h1,1,0,0);
    endfunction
endclass
