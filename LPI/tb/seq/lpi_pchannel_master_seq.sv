//==============================================================================
// lpi_pchannel_master_seq.sv
// P-Channel MASTER = CONTROLLER initiator BASE sequence.
// Issues n_req power-state transition requests. Scenario sequences override
// next_pstate() to choose the requested PSTATE for each cycle (default random).
//==============================================================================
class lpi_pchannel_master_seq extends uvm_sequence #(lpi_pchannel_item);
  `uvm_object_utils(lpi_pchannel_master_seq)
  rand int unsigned n_req = 20;
  function new(string name="lpi_pchannel_master_seq"); super.new(name); endfunction

  // Override in scenario sequences to drive a specific power-state order.
  virtual function bit [`LPI_PSTATE_W-1:0] next_pstate(int idx);
    case ($urandom_range(0,3))
      0      : return PSTATE_OFF;
      1      : return PSTATE_FULL_RET;
      2      : return PSTATE_WARM_RST;
      default: return PSTATE_ON;
    endcase
  endfunction

  task body();
    for (int i = 0; i < n_req; i++) begin
      bit [`LPI_PSTATE_W-1:0] ps = next_pstate(i);
      lpi_pchannel_item it = lpi_pchannel_item::type_id::create("it");
      start_item(it);
      if (!it.randomize() with { pstate == ps; }) `uvm_error(get_type_name(),"rand failed")
      finish_item(it);
    end
  endtask
endclass
