//-----------------------------------------------------------------------------
// dma350_lpi.sv
//
// Low Power Interface controllers for the DMA-350 (TRM "LPI power P-Channel and
// Power P-Channel" / Appendix A Tables A-2, A-3).
//
//   dma350_qchannel : clock Q-Channel. Accepts a clock quiescence request only
//                     when the DMAC is idle; denies while busy. Drives qactive
//                     whenever there is pending work or a wake-up.
//
//   dma350_pchannel : power P-Channel. Accepts the ON power state immediately;
//                     accepts a low-power / retention state only when idle,
//                     otherwise denies. Reports the active power state vector.
//
// Both implement the standard AMBA four-state LPI handshakes.
//-----------------------------------------------------------------------------
`default_nettype none

// ------------------------------------------------------------- Q-Channel
module dma350_qchannel (
    input  wire   clk,
    input  wire   resetn,

    // pin interface
    input  wire   clk_qreqn,     // active-LOW quiescence request
    output reg    clk_qacceptn,  // active-LOW accept
    output reg    clk_qdeny,     // deny
    output reg    clk_qactive,   // DMAC active / wants to stay clocked

    // core status
    input  wire   busy,          // any channel active / outstanding AXI
    input  wire   wakeup         // pending APB/AXI activity (pwakeup|awakeup)
);
    typedef enum logic [2:0] {
        QRUN, QREQUEST, QSTOPPED, QEXIT, QDENIED, QCONTINUE
    } q_t;
    q_t st;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            st <= QRUN;
            clk_qacceptn <= 1'b1;   // deasserted (not accepting)
            clk_qdeny    <= 1'b0;
            clk_qactive  <= 1'b1;
        end else begin
            // qactive reflects "has work or wants to wake"
            clk_qactive <= busy | wakeup;

            case (st)
                QRUN: begin
                    clk_qacceptn <= 1'b1;
                    clk_qdeny    <= 1'b0;
                    if (!clk_qreqn) st <= QREQUEST;   // request asserted
                end
                QREQUEST: begin
                    if (busy | wakeup) begin
                        clk_qdeny <= 1'b1;            // cannot quiesce: deny
                        st        <= QDENIED;
                    end else begin
                        clk_qacceptn <= 1'b0;        // accept quiescence
                        st           <= QSTOPPED;
                    end
                end
                QSTOPPED: begin
                    if (clk_qreqn) st <= QEXIT;       // request released
                end
                QEXIT: begin
                    clk_qacceptn <= 1'b1;
                    st           <= QRUN;
                end
                QDENIED: begin
                    if (clk_qreqn) st <= QCONTINUE;
                end
                QCONTINUE: begin
                    clk_qdeny <= 1'b0;
                    st        <= QRUN;
                end
                default: st <= QRUN;
            endcase
        end
    end
endmodule

// ------------------------------------------------------------- P-Channel
// Four power states: ON, FULL_RET (full retention), WARM_RST (warm reset) and
// OFF. ON is always accepted; the lower-power states are accepted only when the
// DMAC is idle, subject to DISMINPWR (forbids the deepest OFF state) and
// IDLERETEN (gates retention). pactive reports ON([8]) and FULL_RET([5]) per
// Appendix A (the other states report no active power domain).
module dma350_pchannel #(
    parameter logic [3:0] PSTATE_ON       = 4'h8,
    parameter logic [3:0] PSTATE_FULL_RET = 4'h5,
    parameter logic [3:0] PSTATE_WARM_RST = 4'h2,
    parameter logic [3:0] PSTATE_OFF      = 4'h0
)(
    input  wire        clk,
    input  wire        resetn,

    // pin interface
    input  wire        preq,
    input  wire [3:0]  pstate,
    output reg         paccept,
    output reg         pdeny,
    output reg  [9:0]  pactive,

    // core status / power-policy controls
    input  wire        busy,
    input  wire        dis_min_pwr,   // DISMINPWR: forbid the deepest OFF state
    input  wire        idle_reten,    // IDLERETEN: allow FULL_RET retention
    output wire        in_warm_rst    // WARM_RST accepted: pause all channels
);
    typedef enum logic [1:0] {P_IDLE, P_ACCEPT, P_DENY} p_t;
    p_t st;
    reg  [3:0] cur_state;

    // an accepted WARM_RST power state pauses all channel operation (TRM 5.9.1.1);
    // exiting back to ON resumes it.
    assign in_warm_rst = (cur_state == PSTATE_WARM_RST);

    // whether a requested target state may be entered right now
    function automatic logic can_enter(input [3:0] req, input logic b);
        case (req)
            PSTATE_ON:       can_enter = 1'b1;            // always allowed
            PSTATE_FULL_RET: can_enter = ~b & idle_reten; // retention if idle+enabled
            PSTATE_WARM_RST: can_enter = 1'b1;            // accepted; pauses channels
            PSTATE_OFF:      can_enter = ~b & ~dis_min_pwr;// off when idle, unless dis
            default:         can_enter = 1'b0;            // unknown state: deny
        endcase
    endfunction

    always_comb begin
        // pactive: which power states are currently active (Appendix A).
        pactive        = 10'b0;
        pactive[8]     = (cur_state == PSTATE_ON);
        pactive[5]     = (cur_state == PSTATE_FULL_RET);
    end

    always_ff @(posedge clk) begin
        if (!resetn) begin
            st        <= P_IDLE;
            paccept   <= 1'b0;
            pdeny     <= 1'b0;
            cur_state <= PSTATE_ON;
        end else begin
            case (st)
                P_IDLE: begin
                    paccept <= 1'b0;
                    pdeny   <= 1'b0;
                    if (preq) begin
                        if (can_enter(pstate, busy)) begin
                            paccept   <= 1'b1;
                            cur_state <= pstate;
                            st        <= P_ACCEPT;
                        end else begin
                            pdeny <= 1'b1;
                            st    <= P_DENY;
                        end
                    end
                end
                P_ACCEPT: if (!preq) begin paccept <= 1'b0; st <= P_IDLE; end
                P_DENY:   if (!preq) begin pdeny   <= 1'b0; st <= P_IDLE; end
                default:  st <= P_IDLE;
            endcase
        end
    end
endmodule

`default_nettype wire
