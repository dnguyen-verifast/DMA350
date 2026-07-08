// CH_BUILDCFG0 - Offset 0xF8 - RO - reset IMPLEMENTATION DEFINED
// Channel Build Configuration and Capability register 0.
// NOTE: DATA_WIDTH / ADDR_WIDTH / CMD_BUFF_SIZE / DATA_BUFF_SIZE are config-parameter
//       dependent; reset values below are placeholders (0) except the documented INC_WIDTH=0xf.
class ch_buildcfg0_reg extends uvm_reg;
    rand uvm_reg_field INC_WIDTH;
    rand uvm_reg_field DATA_WIDTH;
    rand uvm_reg_field ADDR_WIDTH;
    rand uvm_reg_field CMD_BUFF_SIZE;
    rand uvm_reg_field DATA_BUFF_SIZE;

    `uvm_object_utils(ch_buildcfg0_reg)
    function new(string name = "ch_buildcfg0_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.INC_WIDTH      = uvm_reg_field::type_id::create("INC_WIDTH",, get_full_name());
        this.DATA_WIDTH     = uvm_reg_field::type_id::create("DATA_WIDTH",, get_full_name());
        this.ADDR_WIDTH     = uvm_reg_field::type_id::create("ADDR_WIDTH",, get_full_name());
        this.CMD_BUFF_SIZE  = uvm_reg_field::type_id::create("CMD_BUFF_SIZE",, get_full_name());
        this.DATA_BUFF_SIZE = uvm_reg_field::type_id::create("DATA_BUFF_SIZE",, get_full_name());

        //                     parent size lsb access volatile reset has_reset is_rand indiv_access
        this.INC_WIDTH.configure(     this,4,26,"RO",0,4'hf,1,0,0);
        this.DATA_WIDTH.configure(    this,3,22,"RO",0,3'h0,1,0,0);
        this.ADDR_WIDTH.configure(    this,6,16,"RO",0,6'h0,1,0,0);
        this.CMD_BUFF_SIZE.configure( this,8, 8,"RO",0,8'h0,1,0,0);
        this.DATA_BUFF_SIZE.configure(this,8, 0,"RO",0,8'h0,1,0,0);
    endfunction
endclass
