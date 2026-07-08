//==============================================================================
// lpi_qchannel_master_deny_seq.sv
// Q-Channel DEVICE responder : ALWAYS DENY (exercises the denied-quiescence
// path Q_RUN->Q_REQUEST->Q_DENIED->Q_CONTINUE->Q_RUN, Figure 2-3).
//==============================================================================
class lpi_qchannel_master_deny_seq extends lpi_qchannel_master_seq;
  `uvm_object_utils(lpi_qchannel_master_deny_seq)
  function new(string name="lpi_qchannel_master_deny_seq"); super.new(name); endfunction
  virtual function bit next_deny(int idx); return 1'b1; endfunction
endclass
