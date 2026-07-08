// CH_DESTMPLT - Offset 0x48 - RW - reset 0x00000001
// Channel Destination Template Pattern. Bit[0] (DESTMPLTLSB) is RO and fixed to 1.
class ch_destmplt_reg extends uvm_reg;
    rand uvm_reg_field DESTMPLT;
    rand uvm_reg_field DESTMPLTLSB;

    `uvm_object_utils(ch_destmplt_reg)
    function new(string name = "ch_destmplt_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.DESTMPLT    = uvm_reg_field::type_id::create("DESTMPLT",, get_full_name());
        this.DESTMPLTLSB = uvm_reg_field::type_id::create("DESTMPLTLSB",, get_full_name());
        //                  parent size lsb access volatile reset has_reset is_rand indiv_access
        this.DESTMPLT.configure(   this,31,1,"RW",0,31'h0,1,0,0);
        this.DESTMPLTLSB.configure(this, 1,0,"RO",0, 1'h1,1,0,0);
    endfunction
endclass
