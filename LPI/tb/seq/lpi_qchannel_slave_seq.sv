//==============================================================================
// lpi_qchannel_slave_seq.sv
// Q-Channel SLAVE = CONTROLLER initiator sequence : issue N quiescence
// request/exit cycles.
//==============================================================================
class lpi_qchannel_slave_seq extends uvm_sequence #(lpi_qchannel_item);
  `uvm_object_utils(lpi_qchannel_slave_seq)
  rand int unsigned n_req = 20;
  function new(string name="lpi_qchannel_slave_seq"); super.new(name); endfunction
  task body();
    repeat (n_req) begin
      lpi_qchannel_item it = lpi_qchannel_item::type_id::create("it");
      start_item(it);
      if (!it.randomize()) `uvm_error(get_type_name(),"rand failed")
      finish_item(it);
    end
  endtask
endclass
