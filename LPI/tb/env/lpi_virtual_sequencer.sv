//==============================================================================
// lpi_virtual_sequencer.sv
// Virtual sequencer : handles to the master and slave sub-sequencers of both
// channels, so one virtual sequence can coordinate the whole environment.
//==============================================================================
class lpi_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(lpi_virtual_sequencer)

  uvm_sequencer #(lpi_qchannel_item) q_master_seqr;
  uvm_sequencer #(lpi_qchannel_item) q_slave_seqr;
  uvm_sequencer #(lpi_pchannel_item) p_master_seqr;
  uvm_sequencer #(lpi_pchannel_item) p_slave_seqr;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction
endclass
