//==============================================================================
// lpi_pchannel_coverage.sv
// Functional coverage : interface states, power states, and edges.
//==============================================================================
class lpi_pchannel_coverage extends uvm_subscriber #(lpi_pchannel_item);
  `uvm_component_utils(lpi_pchannel_coverage)
  lpi_pchannel_item tr;

  covergroup cg;
    option.per_instance = 1;
    cp_prev : coverpoint tr.prev_state { bins s[] = {P_STABLE,P_REQUEST,P_ACCEPT,P_COMPLETE,P_DENIED,P_CONTINUE}; }
    cp_curr : coverpoint tr.curr_state { bins s[] = {P_STABLE,P_REQUEST,P_ACCEPT,P_COMPLETE,P_DENIED,P_CONTINUE}; }
    // Dedicated coverpoint for the illegal combination (PACCEPT=1, PDENY=1,
    // Table 3-1 'Unused'). In correct operation this bin must stay at 0 hits.
    cp_illegal : coverpoint tr.curr_state { bins illegal = {P_ILLEGAL}; }
    // 4 supported power states
    cp_state: coverpoint tr.pstate {
      bins OFF       = {PSTATE_OFF};
      bins FULL_RET  = {PSTATE_FULL_RET};
      bins WARM_RST  = {PSTATE_WARM_RST};
      bins ON        = {PSTATE_ON};
    }
    x_edge  : cross cp_prev, cp_curr;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name,parent); cg = new();
  endfunction
  function void write(lpi_pchannel_item t); tr = t; cg.sample(); endfunction
endclass
