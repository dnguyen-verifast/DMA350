// CH_AIDR - Offset 0xCC - RO - reset IMPLEMENTATION DEFINED
// Channel Architecture Identification register.
class ch_aidr_reg extends uvm_reg;
    rand uvm_reg_field ARCH_MAJOR_REV;
    rand uvm_reg_field ARCH_MINOR_REV;

    `uvm_object_utils(ch_aidr_reg)
    function new(string name = "ch_aidr_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.ARCH_MAJOR_REV = uvm_reg_field::type_id::create("ARCH_MAJOR_REV",, get_full_name());
        this.ARCH_MINOR_REV = uvm_reg_field::type_id::create("ARCH_MINOR_REV",, get_full_name());
        //                     parent size lsb access volatile reset has_reset is_rand indiv_access
        this.ARCH_MAJOR_REV.configure(this,4,4,"RO",0,4'h0,1,0,0);
        this.ARCH_MINOR_REV.configure(this,4,0,"RO",0,4'h0,1,0,0);
    endfunction
endclass
