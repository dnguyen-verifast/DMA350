//==============================================================================
// lpi_pchannel_master_walk_seq.sv
// P-Channel CONTROLLER scenario : directed power-state WALK
//   ON -> Warm reset -> Full retention -> OFF -> ON -> ...
// Exercises multiple state transitions (Figure 3-7) across all 4 power states.
//==============================================================================
class lpi_pchannel_master_walk_seq extends lpi_pchannel_master_seq;
  `uvm_object_utils(lpi_pchannel_master_walk_seq)
  function new(string name="lpi_pchannel_master_walk_seq"); super.new(name); endfunction

  virtual function bit [`LPI_PSTATE_W-1:0] next_pstate(int idx);
    bit [`LPI_PSTATE_W-1:0] walk[5];
    walk = '{PSTATE_ON, PSTATE_WARM_RST, PSTATE_FULL_RET, PSTATE_OFF, PSTATE_ON};
    return walk[idx % 5];
  endfunction
endclass
