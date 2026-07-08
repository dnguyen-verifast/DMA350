// NSEC_CHINTRSTATUS0 - Offset 0x00 - RO - reset 0x00000000
// Collated Non-secure channel interrupt flags for channel 0..NUM_CHANNELS-1.
// NOTE: field width = NUM_CHANNELS (max 8); modeled as 8 bits, [31:NUM_CHANNELS] reserved.
class nsec_chintrstatus0_reg extends uvm_reg;
    rand uvm_reg_field CHINTRSTATUS0;

    `uvm_object_utils(nsec_chintrstatus0_reg)
    function new(string name = "nsec_chintrstatus0_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.CHINTRSTATUS0 = uvm_reg_field::type_id::create("CHINTRSTATUS0",, get_full_name());
        //                    parent size lsb access volatile reset has_reset is_rand indiv_access
        this.CHINTRSTATUS0.configure(this,8,0,"RO",1,8'h0,1,0,0);
    endfunction
endclass
