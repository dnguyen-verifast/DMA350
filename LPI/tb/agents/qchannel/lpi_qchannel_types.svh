//==============================================================================
// lpi_qchannel_types.svh
// Q-Channel package-scope types and helpers (Table 2-1, Figure 2-6).
//==============================================================================
`ifndef LPI_QCHANNEL_TYPES_SVH
`define LPI_QCHANNEL_TYPES_SVH

  // Interface state enumeration
  typedef enum logic [2:0] {
    Q_RUN,        // 1 1 0
    Q_REQUEST,    // 0 1 0
    Q_STOPPED,    // 0 0 0
    Q_EXIT,       // 1 0 0
    Q_DENIED,     // 0 1 1
    Q_CONTINUE,   // 1 1 1
    Q_ILLEGAL     // x 0 1  (Unused/illegal)
  } q_state_e;

  // Decode {qreqn, qacceptn, qdeny} -> state
  function automatic q_state_e q_decode(bit qreqn, bit qacceptn, bit qdeny);
    casez ({qreqn, qacceptn, qdeny})
      3'b110 : return Q_RUN;
      3'b010 : return Q_REQUEST;
      3'b000 : return Q_STOPPED;
      3'b100 : return Q_EXIT;
      3'b011 : return Q_DENIED;
      3'b111 : return Q_CONTINUE;
      3'b?01 : return Q_ILLEGAL;   // qacceptn=0, qdeny=1
      default: return Q_ILLEGAL;
    endcase
  endfunction

`endif // LPI_QCHANNEL_TYPES_SVH
