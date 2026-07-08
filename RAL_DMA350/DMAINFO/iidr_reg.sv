// IIDR - Offset 0xC8 - RO - reset IMPLEMENTATION DEFINED
// DMA unit Implementation Identification register.
class iidr_reg extends uvm_reg;
    rand uvm_reg_field PRODUCTID;
    rand uvm_reg_field VARIANT;
    rand uvm_reg_field REVISION;
    rand uvm_reg_field IMPLEMENTER;

    `uvm_object_utils(iidr_reg)
    function new(string name = "iidr_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.PRODUCTID   = uvm_reg_field::type_id::create("PRODUCTID",, get_full_name());
        this.VARIANT     = uvm_reg_field::type_id::create("VARIANT",, get_full_name());
        this.REVISION    = uvm_reg_field::type_id::create("REVISION",, get_full_name());
        this.IMPLEMENTER = uvm_reg_field::type_id::create("IMPLEMENTER",, get_full_name());

        //                  parent size lsb access volatile reset has_reset is_rand indiv_access
        this.PRODUCTID.configure(  this,12,20,"RO",0,12'h3a0,1,0,0);
        this.VARIANT.configure(    this, 4,16,"RO",0, 4'h0,  1,0,0);
        this.REVISION.configure(   this, 4,12,"RO",0, 4'h0,  1,0,0);
        this.IMPLEMENTER.configure(this,12, 0,"RO",0,12'h43b,1,0,0);
    endfunction
endclass
