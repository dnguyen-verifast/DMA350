//==============================================================================
// lpi_qchannel_master_accept_seq.sv
// Q-Channel DEVICE responder : ALWAYS ACCEPT (exercises the accepted-quiescence
// path Q_RUN->Q_REQUEST->Q_STOPPED->Q_EXIT->Q_RUN, Figure 2-2).
//==============================================================================
class lpi_qchannel_master_accept_seq extends lpi_qchannel_master_seq;
  `uvm_object_utils(lpi_qchannel_master_accept_seq)
  function new(string name="lpi_qchannel_master_accept_seq"); super.new(name); endfunction
  virtual function bit next_deny(int idx); return 1'b0; endfunction
endclass
