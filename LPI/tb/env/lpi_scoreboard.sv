//==============================================================================
// lpi_scoreboard.sv
// ONE common scoreboard for BOTH interfaces (Q-Channel and P-Channel) AND both
// roles (master, slave). Each role has its own monitor, so the scoreboard
// exposes four analysis imports and checks state-transition legality on each
// independent observation:
//   - Q-Channel : Figure 2-6 graph
//   - P-Channel : Figure 3-8 graph
//==============================================================================

// One write() entry point per (channel, role)
`uvm_analysis_imp_decl(_qm)   // Q master
`uvm_analysis_imp_decl(_qs)   // Q slave
`uvm_analysis_imp_decl(_pm)   // P master
`uvm_analysis_imp_decl(_ps)   // P slave

class lpi_scoreboard extends uvm_component;
  `uvm_component_utils(lpi_scoreboard)

  uvm_analysis_imp_qm #(lpi_qchannel_item, lpi_scoreboard) q_master_imp;
  uvm_analysis_imp_qs #(lpi_qchannel_item, lpi_scoreboard) q_slave_imp;
  uvm_analysis_imp_pm #(lpi_pchannel_item, lpi_scoreboard) p_master_imp;
  uvm_analysis_imp_ps #(lpi_pchannel_item, lpi_scoreboard) p_slave_imp;

  int unsigned q_master_trans, q_slave_trans;
  int unsigned p_master_trans, p_slave_trans;
  int unsigned q_errors, p_errors;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    q_master_imp = new("q_master_imp", this);
    q_slave_imp  = new("q_slave_imp",  this);
    p_master_imp = new("p_master_imp", this);
    p_slave_imp  = new("p_slave_imp",  this);
  endfunction

  //--------------------------------------------------------------------------
  // Q-Channel legality (Figure 2-6)
  //--------------------------------------------------------------------------
  function bit q_legal(q_state_e p, q_state_e c);
    case (p)
      Q_RUN      : return (c inside {Q_REQUEST});
      Q_REQUEST  : return (c inside {Q_STOPPED, Q_DENIED});
      Q_STOPPED  : return (c inside {Q_EXIT});
      Q_EXIT     : return (c inside {Q_RUN});
      Q_DENIED   : return (c inside {Q_CONTINUE});
      Q_CONTINUE : return (c inside {Q_RUN});
      default    : return 1'b0;
    endcase
  endfunction

  function void check_q(lpi_qchannel_item t, string role);
    if (t.curr_state == Q_ILLEGAL) begin
      q_errors++;
      `uvm_error($sformatf("LPI_SB/Q_%s",role),
        $sformatf("Illegal Q state reached from %s", t.prev_state.name()))
    end
    else if (!q_legal(t.prev_state, t.curr_state)) begin
      q_errors++;
      `uvm_error($sformatf("LPI_SB/Q_%s",role),
        $sformatf("Illegal Q transition %s -> %s", t.prev_state.name(), t.curr_state.name()))
    end
    else
      `uvm_info($sformatf("LPI_SB/Q_%s",role),
        $sformatf("OK %s -> %s", t.prev_state.name(), t.curr_state.name()), UVM_HIGH)
  endfunction

  //--------------------------------------------------------------------------
  // P-Channel legality (Figure 3-8)
  //--------------------------------------------------------------------------
  function bit p_legal(p_state_e p, p_state_e c);
    case (p)
      P_RESET    : return (c inside {P_STABLE, P_REQUEST});
      P_STABLE   : return (c inside {P_REQUEST, P_RESET});
      P_REQUEST  : return (c inside {P_ACCEPT, P_DENIED});
      P_ACCEPT   : return (c inside {P_COMPLETE});
      P_COMPLETE : return (c inside {P_STABLE, P_RESET});
      P_DENIED   : return (c inside {P_CONTINUE});
      P_CONTINUE : return (c inside {P_STABLE, P_RESET});
      default    : return 1'b0;
    endcase
  endfunction

  function void check_p(lpi_pchannel_item t, string role);
    if (t.curr_state == P_ILLEGAL) begin
      p_errors++;
      `uvm_error($sformatf("LPI_SB/P_%s",role),
        $sformatf("Illegal P state from %s (PACCEPT&PDENY)", t.prev_state.name()))
    end
    else if (!p_legal(t.prev_state, t.curr_state)) begin
      p_errors++;
      `uvm_error($sformatf("LPI_SB/P_%s",role),
        $sformatf("Illegal P transition %s -> %s", t.prev_state.name(), t.curr_state.name()))
    end
    else
      `uvm_info($sformatf("LPI_SB/P_%s",role),
        $sformatf("OK %s -> %s", t.prev_state.name(), t.curr_state.name()), UVM_HIGH)
  endfunction

  //--------------------------------------------------------------------------
  // analysis write() entry points (one per channel/role monitor)
  //--------------------------------------------------------------------------
  function void write_qm(lpi_qchannel_item t); q_master_trans++; check_q(t,"MASTER"); endfunction
  function void write_qs(lpi_qchannel_item t); q_slave_trans++;  check_q(t,"SLAVE");  endfunction
  function void write_pm(lpi_pchannel_item t); p_master_trans++; check_p(t,"MASTER"); endfunction
  function void write_ps(lpi_pchannel_item t); p_slave_trans++;  check_p(t,"SLAVE");  endfunction

  //--------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    `uvm_info("LPI_SB", $sformatf(
      "Q: master_trans=%0d slave_trans=%0d errors=%0d | P: master_trans=%0d slave_trans=%0d errors=%0d",
      q_master_trans, q_slave_trans, q_errors,
      p_master_trans, p_slave_trans, p_errors), UVM_LOW)
  endfunction
endclass
