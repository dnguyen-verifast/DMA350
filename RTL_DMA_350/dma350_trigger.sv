//-----------------------------------------------------------------------------
// dma350_trigger.sv
//
// Trigger interface handshake helpers for the DMA-350 (TRM "Trigger interface"
// / Appendix A Table A-7). Two primitives:
//
//   dma350_trig_in  : receives a four-phase request from a flow-control capable
//                     peripheral (trig_in_<TI>_req / _req_type) and presents it
//                     to the channel matrix as a latched pending event. The
//                     channel consumes it (take) and the block drives the
//                     four-phase acknowledge (trig_in_<TI>_ack / _ack_type).
//
//   dma350_trig_out : drives a four-phase request to a peripheral
//                     (trig_out_<TO>_req) when a channel asks (start) and
//                     reports completion (done) once acknowledged
//                     (trig_out_<TO>_ack).
//
// Both follow the AMBA four-phase request/acknowledge convention: assert,
// wait accept, deassert, wait accept-drop.
//-----------------------------------------------------------------------------
`default_nettype none

// ------------------------------------------------------------------ trig in
module dma350_trig_in import dma350_pkg::*; (
    input  wire        clk,
    input  wire        resetn,

    // external peripheral side
    input  wire        trig_in_req,
    input  wire [1:0]  trig_in_req_type,
    output reg         trig_in_ack,
    output reg  [1:0]  trig_in_ack_type,

    // channel-matrix side
    output reg         pending,        // a trigger is waiting to be consumed
    output reg  [1:0]  pending_type,
    input  wire        take,           // 1-cycle: channel consumed the trigger
    input  wire        take_last,      // with take: acknowledge with LAST OKAY
    input  wire        deny            // 1-cycle: refuse the pending trigger
);
    typedef enum logic [1:0] {T_IDLE, T_PEND, T_ACK} st_t;
    st_t st;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            st <= T_IDLE;
            trig_in_ack <= 1'b0; trig_in_ack_type <= TRIGACK_OKAY;
            pending <= 1'b0; pending_type <= TRIGREQ_SINGLE;
        end else begin
            case (st)
                T_IDLE: begin
                    trig_in_ack <= 1'b0;
                    pending     <= 1'b0;
                    if (trig_in_req) begin
                        pending      <= 1'b1;
                        pending_type <= trig_in_req_type;
                        st           <= T_PEND;
                    end
                end
                T_PEND: begin
                    // hold pending until the channel consumes (or SW denies) it
                    if (deny) begin
                        pending          <= 1'b0;
                        trig_in_ack      <= 1'b1;          // phase 3: acknowledge
                        trig_in_ack_type <= TRIGACK_DENY;  // refused (TRM Table 5-5)
                        st               <= T_ACK;
                    end else if (take) begin
                        pending          <= 1'b0;
                        trig_in_ack      <= 1'b1;          // phase 3: acknowledge
                        trig_in_ack_type <= take_last ? TRIGACK_LASTOKAY
                                                      : TRIGACK_OKAY;
                        st               <= T_ACK;
                    end
                end
                T_ACK: begin
                    // phase 4: drop ack once the request is released
                    if (!trig_in_req) begin
                        trig_in_ack <= 1'b0;
                        st          <= T_IDLE;
                    end
                end
                default: st <= T_IDLE;
            endcase
        end
    end
endmodule

// ----------------------------------------------------------------- trig out
module dma350_trig_out (
    input  wire        clk,
    input  wire        resetn,

    // external peripheral side
    output reg         trig_out_req,
    input  wire        trig_out_ack,

    // channel-matrix side
    input  wire        start,          // 1-cycle: launch a trigger-out
    output reg         busy,
    output reg         done            // 1-cycle: handshake complete
);
    typedef enum logic [1:0] {O_IDLE, O_REQ, O_DROP} st_t;
    st_t st;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            st <= O_IDLE;
            trig_out_req <= 1'b0; busy <= 1'b0; done <= 1'b0;
        end else begin
            done <= 1'b0;
            case (st)
                O_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        trig_out_req <= 1'b1;     // phase 1: request
                        busy         <= 1'b1;
                        st           <= O_REQ;
                    end
                end
                O_REQ: begin
                    if (trig_out_ack) begin       // phase 2: accepted
                        trig_out_req <= 1'b0;      // phase 3: drop request
                        st           <= O_DROP;
                    end
                end
                O_DROP: begin
                    if (!trig_out_ack) begin       // phase 4: ack released
                        busy <= 1'b0;
                        done <= 1'b1;
                        st   <= O_IDLE;
                    end
                end
                default: st <= O_IDLE;
            endcase
        end
    end
endmodule

`default_nettype wire
