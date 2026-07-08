// SCFG_CTRL - Offset 0x40 - RW - reset 0x00000000
// Security Configuration Control (lock + Secure access violation response).
class scfg_ctrl_reg extends uvm_reg;
    rand uvm_reg_field SEC_CFG_LCK;
    rand uvm_reg_field RSPTYPE_SECACCVIO;
    rand uvm_reg_field INTREN_SECACCVIO;

    `uvm_object_utils(scfg_ctrl_reg)
    function new(string name = "scfg_ctrl_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.SEC_CFG_LCK       = uvm_reg_field::type_id::create("SEC_CFG_LCK",, get_full_name());
        this.RSPTYPE_SECACCVIO = uvm_reg_field::type_id::create("RSPTYPE_SECACCVIO",, get_full_name());
        this.INTREN_SECACCVIO  = uvm_reg_field::type_id::create("INTREN_SECACCVIO",, get_full_name());

        //                      parent size lsb access volatile reset has_reset is_rand indiv_access
        this.SEC_CFG_LCK.configure(      this,1,31,"RW",0,1'h0,1,0,0);
        this.RSPTYPE_SECACCVIO.configure(this,1, 1,"RW",0,1'h0,1,0,0);
        this.INTREN_SECACCVIO.configure( this,1, 0,"RW",0,1'h0,1,0,0);
    endfunction
endclass
