//==============================================================================
// crlp_seq_lib.svh : reusable sequences for the CRLP agent
//==============================================================================
`ifndef CRLP_SEQ_LIB_SVH
`define CRLP_SEQ_LIB_SVH

//------------------------------------------------------------------------------
// Base sequence
//------------------------------------------------------------------------------
class crlp_base_seq extends uvm_sequence #(crlp_seq_item);
  `uvm_object_utils(crlp_base_seq)
  function new(string name = "crlp_base_seq"); super.new(name); endfunction

  // Small helper to issue one op and return the completed item.
  // Randomize first (applies soft defaults to aclken/pstate), then override the
  // directed fields.  This avoids the randomize()-with scoping trap where
  // unqualified names would bind to the item's members, not the task args.
  task automatic do_op(crlp_op_e op, bit [3:0] pstate = 4'hF,
                       int unsigned rst_cyc = 0, time period = 0,
                       output crlp_seq_item done);
    crlp_seq_item it = crlp_seq_item::type_id::create("it");
    start_item(it);
    if (!it.randomize())
      `uvm_error(get_type_name(), "randomize failed")
    it.op            = op;
    it.pstate        = pstate;
    it.reset_cycles  = rst_cyc;
    it.clk_period_ps = period;
    finish_item(it);
    done = it;
  endtask
endclass

//------------------------------------------------------------------------------
// Power-on reset : start clock, then apply reset pulse
//------------------------------------------------------------------------------
class crlp_por_seq extends crlp_base_seq;
  `uvm_object_utils(crlp_por_seq)
  rand int unsigned reset_cycles = 5;
  function new(string name = "crlp_por_seq"); super.new(name); endfunction

  virtual task body();
    crlp_seq_item d;
    do_op(OP_CLK_START, , , , d);
    do_op(OP_RESET, , reset_cycles, , d);
  endtask
endclass

//------------------------------------------------------------------------------
// Q-Channel clock quiescence entry + exit
//------------------------------------------------------------------------------
class crlp_qch_cycle_seq extends crlp_base_seq;
  `uvm_object_utils(crlp_qch_cycle_seq)
  function new(string name = "crlp_qch_cycle_seq"); super.new(name); endfunction

  virtual task body();
    crlp_seq_item d;
    do_op(OP_QCH_QUIESCE, , , , d);
    if (d.rsp == RSP_ACCEPT) begin
      `uvm_info(get_type_name(),
        $sformatf("Quiesced in %0d cy; now waking", d.latency_cy), UVM_LOW)
      do_op(OP_QCH_WAKE, , , , d);
    end
    else begin
      `uvm_info(get_type_name(),
        $sformatf("Quiescence not granted (%s)", d.rsp.name()), UVM_LOW)
    end
  endtask
endclass

//------------------------------------------------------------------------------
// P-Channel power-state change
//------------------------------------------------------------------------------
class crlp_pch_seq extends crlp_base_seq;
  `uvm_object_utils(crlp_pch_seq)
  rand bit [3:0] target_state;
  constraint c_def { soft target_state == PSTATE_ON_FULL; }
  function new(string name = "crlp_pch_seq"); super.new(name); endfunction

  virtual task body();
    crlp_seq_item d;
    do_op(OP_PCH_REQ, target_state, , , d);
  endtask
endclass

//------------------------------------------------------------------------------
// Full low-power flow : POR -> Q-Channel quiesce/wake -> P-Channel to OFF & ON
//------------------------------------------------------------------------------
class crlp_lowpower_flow_seq extends crlp_base_seq;
  `uvm_object_utils(crlp_lowpower_flow_seq)
  function new(string name = "crlp_lowpower_flow_seq"); super.new(name); endfunction

  virtual task body();
    crlp_por_seq        por = crlp_por_seq::type_id::create("por");
    crlp_qch_cycle_seq  qch = crlp_qch_cycle_seq::type_id::create("qch");
    crlp_pch_seq        p_off = crlp_pch_seq::type_id::create("p_off");
    crlp_pch_seq        p_on  = crlp_pch_seq::type_id::create("p_on");

    por.start(m_sequencer);
    qch.start(m_sequencer);

    if (!p_off.randomize() with { target_state == PSTATE_RET; })
      `uvm_error(get_type_name(), "randomize p_off failed")
    p_off.start(m_sequencer);

    if (!p_on.randomize() with { target_state == PSTATE_ON_FULL; })
      `uvm_error(get_type_name(), "randomize p_on failed")
    p_on.start(m_sequencer);
  endtask
endclass

`endif // CRLP_SEQ_LIB_SVH
