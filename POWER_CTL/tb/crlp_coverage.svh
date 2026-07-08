//==============================================================================
// crlp_coverage.svh : functional coverage subscriber for CRLP transactions
//==============================================================================
`ifndef CRLP_COVERAGE_SVH
`define CRLP_COVERAGE_SVH

class crlp_coverage extends uvm_subscriber #(crlp_seq_item);
  `uvm_component_utils(crlp_coverage)

  crlp_seq_item tr;

  covergroup cg_crlp;
    option.per_instance = 1;

    cp_op : coverpoint tr.op;

    cp_rsp : coverpoint tr.rsp {
      bins accept  = {RSP_ACCEPT};
      bins deny    = {RSP_DENY};
      bins timeout = {RSP_TIMEOUT};
      ignore_bins none = {RSP_NONE};
    }

    cp_pstate : coverpoint tr.pstate {
      bins off      = {PSTATE_OFF};
      bins ret      = {PSTATE_RET};
      bins on_clk   = {PSTATE_ON_CLK};
      bins on_full  = {PSTATE_ON_FULL};
      bins others   = default;
    }

    // Q-Channel / P-Channel accept vs deny per op.
    x_op_rsp : cross cp_op, cp_rsp;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_crlp = new();
  endfunction

  function void write(crlp_seq_item t);
    tr = t;
    cg_crlp.sample();
  endfunction

endclass

`endif // CRLP_COVERAGE_SVH
