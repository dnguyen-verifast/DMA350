// SEC_SIGNALVAL - Offset 0xFC - RW (W1C) - reset 0x00000000
// Secure Unit Signal Value selected by SEC_SIGNALPTR. Write-1-to-clear trigger inputs.
class sec_signalval_reg extends uvm_reg;
    rand uvm_reg_field SECSIGNALVAL;

    `uvm_object_utils(sec_signalval_reg)
    function new(string name = "sec_signalval_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.SECSIGNALVAL = uvm_reg_field::type_id::create("SECSIGNALVAL",, get_full_name());
        //                   parent size lsb access volatile reset has_reset is_rand indiv_access
        this.SECSIGNALVAL.configure(this,32,0,"W1C",1,32'h0,1,0,0);
    endfunction
endclass
