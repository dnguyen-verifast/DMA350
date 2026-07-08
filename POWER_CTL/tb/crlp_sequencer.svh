//==============================================================================
// crlp_sequencer.svh
//==============================================================================
`ifndef CRLP_SEQUENCER_SVH
`define CRLP_SEQUENCER_SVH

class crlp_sequencer extends uvm_sequencer #(crlp_seq_item);
  `uvm_component_utils(crlp_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

`endif // CRLP_SEQUENCER_SVH
