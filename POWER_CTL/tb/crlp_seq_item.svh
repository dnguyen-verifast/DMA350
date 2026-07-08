//==============================================================================
// crlp_seq_item.svh : transaction describing one clock/reset/LPI operation
//==============================================================================
`ifndef CRLP_SEQ_ITEM_SVH
`define CRLP_SEQ_ITEM_SVH

class crlp_seq_item extends uvm_sequence_item;

  // ---- Request fields -------------------------------------------------------
  rand crlp_op_e     op;

  // OP_CLK_START : new clock period (ps). 0 -> keep configured period.
  rand time          clk_period_ps;

  // OP_RESET : reset assertion length in cycles. 0 -> use config default.
  rand int unsigned  reset_cycles;

  // OP_SET_CLKEN : static AXI/APB clock enables.
  rand bit           aclken_m0;
  rand bit           aclken_m1;
  rand bit           pclken;

  // OP_PCH_REQ : requested power state.
  rand bit [3:0]     pstate;

  // ---- Response fields (populated by the driver / monitor) -----------------
  crlp_rsp_e         rsp        = RSP_NONE; // outcome of a Q/P handshake
  int unsigned       latency_cy = 0;        // handshake latency in cycles

  `uvm_object_utils_begin(crlp_seq_item)
    `uvm_field_enum(crlp_op_e, op,      UVM_ALL_ON)
    `uvm_field_int (clk_period_ps,      UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (reset_cycles,       UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (aclken_m0,          UVM_ALL_ON)
    `uvm_field_int (aclken_m1,          UVM_ALL_ON)
    `uvm_field_int (pclken,             UVM_ALL_ON)
    `uvm_field_int (pstate,             UVM_ALL_ON | UVM_HEX)
    `uvm_field_enum(crlp_rsp_e, rsp,    UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (latency_cy,         UVM_ALL_ON | UVM_DEC | UVM_NOCOMPARE)
  `uvm_object_utils_end

  // Sensible defaults so directed sequences need not constrain everything.
  constraint c_defaults {
    soft clk_period_ps == 0;
    soft reset_cycles  == 0;
    soft aclken_m0     == 1;
    soft aclken_m1     == 1;
    soft pclken        == 1;
    soft pstate        == PSTATE_ON_FULL;
  }

  function new(string name = "crlp_seq_item");
    super.new(name);
  endfunction

endclass

`endif // CRLP_SEQ_ITEM_SVH
