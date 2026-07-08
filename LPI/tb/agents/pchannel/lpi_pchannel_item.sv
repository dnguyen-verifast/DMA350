//==============================================================================
// lpi_pchannel_item.sv  -  P-Channel sequence item
//==============================================================================
class lpi_pchannel_item extends uvm_sequence_item;

  // Controller intent
  rand bit [`LPI_PSTATE_W-1:0]  pstate;       // requested power state
  rand int unsigned             req_delay;    // idle cycles in P_STABLE
  rand int unsigned             setup_delay;  // PSTATE-before-PREQ margin cycles

  // Device intent
  rand bit                      deny;         // 1 => respond with PDENY
  rand int unsigned             resp_delay;   // cycles before device responds
  rand bit [`LPI_PACTIVE_W-1:0] pactive;      // device PACTIVE bits

  // Monitor capture
  p_state_e prev_state;
  p_state_e curr_state;

  constraint c_delays {
    req_delay   inside {[0:6]};
    setup_delay inside {[0:4]};
    resp_delay  inside {[0:6]};
  }
  constraint c_deny_dist { deny dist {0 := 8, 1 := 2}; }

  // Only request one of the 4 supported power states:
  //   ON / Warm reset mode / Full retention mode / OFF
  constraint c_pstate {
    pstate inside {PSTATE_OFF, PSTATE_FULL_RET, PSTATE_WARM_RST, PSTATE_ON};
  }

  `uvm_object_utils_begin(lpi_pchannel_item)
    `uvm_field_int (pstate,      UVM_ALL_ON)
    `uvm_field_int (req_delay,   UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (setup_delay, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (deny,        UVM_ALL_ON)
    `uvm_field_int (resp_delay,  UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (pactive,     UVM_ALL_ON)
    `uvm_field_enum(p_state_e, prev_state, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_enum(p_state_e, curr_state, UVM_ALL_ON | UVM_NOCOMPARE)
  `uvm_object_utils_end

  function new(string name="lpi_pchannel_item"); super.new(name); endfunction
endclass
