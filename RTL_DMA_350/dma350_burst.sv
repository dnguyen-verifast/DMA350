//-----------------------------------------------------------------------------
// dma350_burst.sv
//
// DMA-350 AXI5 burst generator. Given a start byte-address and a beat count
// (where each beat carries 2^size bytes), it emits a sequence of legal AXI
// burst descriptors (addr, len = beats-1) honouring the DMA-350 / AXI rules:
//
//   INCR bursts:
//     * must not cross a 1KB boundary (DMA-350 burst breakpoint, TRM 4.3.6 -
//       stricter than and therefore also satisfying the AXI 4KB rule)
//     * must not exceed 256 beats (AXI4 AxLEN)
//     * must not exceed MAX_BYTES (1024 for DMA-350) bytes of payload
//     * must not exceed max_beats (SRC/DESMAXBURSTLEN + 1, TRM 6.5.1.11/12)
//   FIXED bursts (fixed-address peripheral access):
//     * address does not advance
//     * limited to 16 beats (AXI FIXED maximum) and max_beats
//
// AxSIZE-aligned start addresses are assumed (a DMA-350 transfer of unit
// 2^TRANSIZE is naturally size-aligned), so every beat carries a full unit.
//
// Protocol: pulse 'start' with addr_in/beats_in/size/fixed valid; the module
// presents burst_valid with addr/len; the consumer raises burst_ready when the
// address has been issued; 'done' pulses after the final burst is accepted.
//-----------------------------------------------------------------------------
`default_nettype none

module dma350_burst #(
    parameter int C_ADDR_WIDTH = 32,
    parameter int C_BEATS_WIDTH = 24,    // total-beats counter width
    parameter int MAX_BYTES     = 1024   // DMA-350 max bytes per burst
)(
    input  wire                      aclk,
    input  wire                      aresetn,

    input  wire                      start,
    input  wire [C_ADDR_WIDTH-1:0]   addr_in,
    input  wire [C_BEATS_WIDTH-1:0]  beats_in,    // total beats in the transfer
    input  wire [2:0]                size,        // AxSIZE (log2 bytes per beat)
    input  wire                      fixed,       // 1 = FIXED, 0 = INCR
    input  wire [8:0]                max_beats,   // MAXBURSTLEN+1 (1..256)

    output reg                       burst_valid,
    output reg  [C_ADDR_WIDTH-1:0]   burst_addr,
    output reg  [7:0]                burst_len,    // beats - 1
    output reg  [8:0]                burst_beats,  // beats (1..256)
    output reg  [1:0]                burst_type,   // AxBURST (FIXED/INCR)
    input  wire                      burst_ready,

    output reg                       busy,
    output reg                       done
);
    localparam [1:0] BT_FIXED = 2'b00, BT_INCR = 2'b01;

    reg [C_ADDR_WIDTH-1:0]  cur_addr;
    reg [C_BEATS_WIDTH:0]   rem_beats;     // beats remaining
    reg [2:0]               size_q;
    reg                     fixed_q;

    // bytes per beat
    wire [12:0] bpb = 13'd1 << size_q;

    // beats left to the next 1KB boundary from cur_addr (INCR only). DMA-350
    // never crosses 1KB address boundaries (TRM 4.3.6 "burst breakpoint").
    wire [12:0] dist_1k     = 13'h0400 - {3'b000, cur_addr[9:0]};
    wire [12:0] beats_to_1k = dist_1k >> size_q;

    // max payload beats = MAX_BYTES / bytes-per-beat
    wire [12:0] beats_max_bytes = MAX_BYTES[12:0] >> size_q;

    // candidate beats this burst
    function automatic [8:0] calc_beats(
        input [C_BEATS_WIDTH:0] rem, input [12:0] b1k,
        input [12:0] bmax, input [8:0] maxb, input is_fixed);
        logic [31:0] m;
        m = rem;
        if (is_fixed) begin
            if (16 < m) m = 16;                 // FIXED: max 16 beats
        end else begin
            if ({19'd0, b1k}  < m) m = b1k;     // 1KB boundary breakpoint
            if ({19'd0, bmax} < m) m = bmax;    // 1024-byte payload cap
            if (256 < m)            m = 256;    // AxLEN max
        end
        if ({23'd0, maxb} < m) m = maxb;        // *MAXBURSTLEN + 1 register limit
        if (m == 0) m = 1;
        return m[8:0];
    endfunction

    wire [8:0] nbeats = calc_beats(rem_beats, beats_to_1k, beats_max_bytes,
                                   max_beats, fixed_q);

    typedef enum logic [1:0] {S_IDLE, S_EMIT, S_NEXT, S_DONE} state_t;
    state_t state;
    wire fire = burst_valid & burst_ready;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state<=S_IDLE; busy<=0; done<=0; burst_valid<=0;
            burst_addr<=0; burst_len<=0; burst_beats<=9'd1; burst_type<=BT_INCR;
            cur_addr<=0; rem_beats<=0; size_q<=0; fixed_q<=0;
        end else begin
            done <= 1'b0;
            case (state)
                S_IDLE: begin
                    burst_valid <= 1'b0; busy <= 1'b0;
                    if (start && |beats_in) begin
                        cur_addr  <= addr_in;
                        rem_beats <= {1'b0, beats_in};
                        size_q    <= size;
                        fixed_q   <= fixed;
                        busy      <= 1'b1;
                        state     <= S_EMIT;
                    end
                end
                S_EMIT: begin
                    burst_valid <= 1'b1;
                    burst_addr  <= cur_addr;
                    burst_len   <= nbeats - 9'd1;
                    burst_beats <= nbeats;
                    burst_type  <= fixed_q ? BT_FIXED : BT_INCR;
                    if (fire) begin
                        burst_valid <= 1'b0;
                        // INCR advances address; FIXED keeps it
                        if (!fixed_q)
                            cur_addr <= cur_addr + (nbeats << size_q);
                        if (rem_beats <= nbeats) begin
                            rem_beats <= '0;
                            state     <= S_DONE;
                        end else begin
                            rem_beats <= rem_beats - nbeats;
                            state     <= S_NEXT;
                        end
                    end
                end
                S_NEXT: begin
                    burst_valid <= 1'b0;
                    state       <= S_EMIT;
                end
                S_DONE: begin
                    burst_valid <= 1'b0; busy <= 1'b0; done <= 1'b1;
                    state       <= S_IDLE;
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire
