//==============================================================================
// lpi_pchannel_types.svh
// P-Channel package-scope types and helpers (Table 3-1, Figure 3-8).
//==============================================================================
`ifndef LPI_PCHANNEL_TYPES_SVH
`define LPI_PCHANNEL_TYPES_SVH

  // -------------------------------------------------------------------------
  // Device POWER state enumeration (section 3.1.3). 4 power states ordered
  // highest -> lowest power:  ON > Warm reset mode > Full retention mode > OFF
  // -------------------------------------------------------------------------
  typedef enum bit [`LPI_PSTATE_W-1:0] {
    PSTATE_OFF       = 2'b00,   // PACTIVE[0] (implicit minimum, may be omitted)
    PSTATE_FULL_RET  = 2'b01,   // PACTIVE[1] : Full retention mode
    PSTATE_WARM_RST  = 2'b10,   // PACTIVE[2] : Warm reset mode
    PSTATE_ON        = 2'b11    // PACTIVE[3] : ON
  } p_power_state_e;

  localparam int PACTIVE_OFF      = 0;
  localparam int PACTIVE_FULL_RET = 1;
  localparam int PACTIVE_WARM_RST = 2;
  localparam int PACTIVE_ON       = 3;

  // -------------------------------------------------------------------------
  // Interface state enumeration
  // -------------------------------------------------------------------------
  typedef enum logic [2:0] {
    P_RESET,      // resetn=0
    P_STABLE,     // 1 0 0 0
    P_REQUEST,    // 1 1 0 0
    P_ACCEPT,     // 1 1 1 0
    P_COMPLETE,   // 1 0 1 0
    P_DENIED,     // 1 1 0 1
    P_CONTINUE,   // 1 0 0 1
    P_ILLEGAL     // paccept=1 && pdeny=1
  } p_state_e;

  function automatic p_state_e p_decode(bit resetn, bit preq, bit paccept, bit pdeny);
    if (!resetn)            return P_RESET;
    if (paccept && pdeny)   return P_ILLEGAL;
    casez ({preq, paccept, pdeny})
      3'b000 : return P_STABLE;
      3'b100 : return P_REQUEST;
      3'b110 : return P_ACCEPT;
      3'b010 : return P_COMPLETE;
      3'b101 : return P_DENIED;
      3'b001 : return P_CONTINUE;
      default: return P_ILLEGAL;
    endcase
  endfunction

`endif // LPI_PCHANNEL_TYPES_SVH
