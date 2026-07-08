//==============================================================================
// lpi_qchannel_item.sv  -  Q-Channel sequence item
//==============================================================================
class lpi_qchannel_item extends uvm_sequence_item;

  // Controller intent: a single quiescence request + exit cycle
  rand int unsigned req_delay;     // idle cycles in Q_RUN before requesting
  rand int unsigned hold_delay;    // cycles to stay in STOPPED/DENIED before exit

  // Device intent (responder)
  rand bit          deny;          // 1 => respond with QDENY (Q_DENIED)
  rand int unsigned resp_delay;    // cycles before device responds
  rand bit          qactive;       // device QACTIVE level to present

  // Monitor capture (filled by monitor)
  q_state_e         prev_state;
  q_state_e         curr_state;

  constraint c_delays {
    req_delay  inside {[0:6]};
    hold_delay inside {[0:6]};
    resp_delay inside {[0:6]};
  }
  constraint c_deny_dist { deny dist {0 := 8, 1 := 2}; }

  `uvm_object_utils_begin(lpi_qchannel_item)
    `uvm_field_int (req_delay,  UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (hold_delay, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (deny,       UVM_ALL_ON)
    `uvm_field_int (resp_delay, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (qactive,    UVM_ALL_ON)
    `uvm_field_enum(q_state_e, prev_state, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_enum(q_state_e, curr_state, UVM_ALL_ON | UVM_NOCOMPARE)
  `uvm_object_utils_end

  function new(string name="lpi_qchannel_item"); super.new(name); endfunction
endclass
