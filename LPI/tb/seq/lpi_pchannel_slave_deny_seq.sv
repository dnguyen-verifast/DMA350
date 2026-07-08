//==============================================================================
// lpi_pchannel_slave_deny_seq.sv
// P-Channel DEVICE responder : ALWAYS DENY (denied-transition path
// P_STABLE->P_REQUEST->P_DENIED->P_CONTINUE->P_STABLE, Figure 3-3).
//==============================================================================
class lpi_pchannel_slave_deny_seq extends lpi_pchannel_slave_seq;
  `uvm_object_utils(lpi_pchannel_slave_deny_seq)
  function new(string name="lpi_pchannel_slave_deny_seq"); super.new(name); endfunction
  virtual function bit next_deny(int idx); return 1'b1; endfunction
endclass
