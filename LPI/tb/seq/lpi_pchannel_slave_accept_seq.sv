//==============================================================================
// lpi_pchannel_slave_accept_seq.sv
// P-Channel DEVICE responder : ALWAYS ACCEPT (accepted-transition path
// P_STABLE->P_REQUEST->P_ACCEPT->P_COMPLETE->P_STABLE, Figure 3-2).
//==============================================================================
class lpi_pchannel_slave_accept_seq extends lpi_pchannel_slave_seq;
  `uvm_object_utils(lpi_pchannel_slave_accept_seq)
  function new(string name="lpi_pchannel_slave_accept_seq"); super.new(name); endfunction
  virtual function bit next_deny(int idx); return 1'b0; endfunction
endclass
