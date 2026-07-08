//==============================================================================
// crlp_types.svh : shared enums / typedefs for the CRLP agent
//==============================================================================
`ifndef CRLP_TYPES_SVH
`define CRLP_TYPES_SVH

  // Operation requested by a sequence item ------------------------------------
  typedef enum bit [2:0] {
    OP_CLK_START,    // start / restart free-running clock generation
    OP_CLK_STOP,     // force-stop clock (bench control, not via Q-Channel)
    OP_RESET,        // apply an active-LOW reset pulse (async LOW, sync HIGH)
    OP_SET_CLKEN,    // set aclken_m0 / aclken_m1 / pclken static enables
    OP_QCH_QUIESCE,  // Q-Channel: request clock quiescence (stop clock)
    OP_QCH_WAKE,     // Q-Channel: request wake-up (exit quiescence)
    OP_PCH_REQ       // P-Channel: request a power-state change
  } crlp_op_e;

  // Q-Channel protocol states (AMBA LPI) --------------------------------------
  //   Q_RUN     : qreqn=1 qacceptn=1 qdeny=0
  //   Q_REQUEST : qreqn=0 (controller asked to stop, awaiting response)
  //   Q_STOPPED : qreqn=0 qacceptn=0 qdeny=0   (clock may be gated)
  //   Q_EXIT    : qreqn=1 from stopped, awaiting qacceptn=1
  //   Q_DENY    : qreqn=0 qacceptn=1 qdeny=1
  //   Q_CONTINUE: qreqn=1 from deny, awaiting qdeny=0
  typedef enum bit [2:0] {
    Q_RUN, Q_REQUEST, Q_STOPPED, Q_EXIT, Q_DENY, Q_CONTINUE
  } crlp_qch_state_e;

  // Handshake result -----------------------------------------------------------
  typedef enum bit [1:0] {
    RSP_NONE,      // not applicable / not yet resolved
    RSP_ACCEPT,    // device accepted (Q_STOPPED / PACCEPT)
    RSP_DENY,      // device denied  (Q_DENY / PDENY)
    RSP_TIMEOUT    // no response within configured timeout
  } crlp_rsp_e;

  // A few symbolic P-Channel states.  Real encodings are device-specific;
  // adjust to match the DMAC IMPLEMENTATION DEFINED power-state map.
  typedef enum bit [3:0] {
    PSTATE_OFF     = 4'h0,
    PSTATE_RET     = 4'h4,   // retention (example)
    PSTATE_ON_CLK  = 4'h8,   // on, clock available (example)
    PSTATE_ON_FULL = 4'hF    // fully on (example)
  } crlp_pstate_e;

`endif // CRLP_TYPES_SVH
