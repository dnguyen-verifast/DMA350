// CH_SRCTMPLT - Offset 0x44 - RW - reset 0x00000001
// Channel Source Template Pattern. Bit[0] (SRCTMPLTLSB) is RO and fixed to 1.
class ch_srctmplt_reg extends uvm_reg;
    rand uvm_reg_field SRCTMPLT;
    rand uvm_reg_field SRCTMPLTLSB;

    `uvm_object_utils(ch_srctmplt_reg)
    function new(string name = "ch_srctmplt_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.SRCTMPLT    = uvm_reg_field::type_id::create("SRCTMPLT",, get_full_name());
        this.SRCTMPLTLSB = uvm_reg_field::type_id::create("SRCTMPLTLSB",, get_full_name());
        //                  parent size lsb access volatile reset has_reset is_rand indiv_access
        this.SRCTMPLT.configure(   this,31,1,"RW",0,31'h0,1,0,0);
        this.SRCTMPLTLSB.configure(this, 1,0,"RO",0, 1'h1,1,0,0);
    endfunction
endclass
