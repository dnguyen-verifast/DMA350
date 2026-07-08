// NSEC_SIGNALVAL - Offset 0xFC - RW (W1C) - reset 0x00000000
// Non-secure Unit Signal Value selected by NSEC_SIGNALPTR. Write-1-to-clear trigger inputs.
class nsec_signalval_reg extends uvm_reg;
    rand uvm_reg_field NSECSIGNALVAL;

    `uvm_object_utils(nsec_signalval_reg)
    function new(string name = "nsec_signalval_reg");
        super.new(name,32,build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        this.NSECSIGNALVAL = uvm_reg_field::type_id::create("NSECSIGNALVAL",, get_full_name());
        //                    parent size lsb access volatile reset has_reset is_rand indiv_access
        this.NSECSIGNALVAL.configure(this,32,0,"W1C",1,32'h0,1,0,0);
    endfunction
endclass
