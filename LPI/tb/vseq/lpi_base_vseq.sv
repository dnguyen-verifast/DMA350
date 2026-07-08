//==============================================================================
// lpi_base_vseq.sv  -  base virtual sequence
//==============================================================================
class lpi_base_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(lpi_base_vseq)
  `uvm_declare_p_sequencer(lpi_virtual_sequencer)

  bit               do_q = 1;
  bit               do_p = 1;
  rand int unsigned n_req = 20;

  constraint c_nreq { n_req inside {[1:200]}; }

  function new(string name="lpi_base_vseq"); super.new(name); endfunction
endclass
