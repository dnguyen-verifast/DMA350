//-----------------------------------------------------------------------------
// dma350_byte_fifo.sv
//
// Per-channel data FIFO for the DMA-350 datapath, organised as a byte gearbox:
// up to WBYTES bytes can be pushed per cycle (the valid, lane-compacted bytes of
// a read beat) and up to WBYTES bytes popped per cycle (placed onto the
// destination byte lanes by the consumer). Because bytes are stored in transfer
// order, this single structure provides BOTH the deep read/write decoupling
// buffer described in the TRM AND the source-to-destination byte realignment
// (no width-aligned-address restriction).
//
// DEPTH (total byte capacity) should be a power of two; it equals
// FIFO_DEPTH * (DATA_WIDTH/8) so the buffer is FIFO_DEPTH bus-words deep.
//-----------------------------------------------------------------------------
`default_nettype none

module dma350_byte_fifo #(
    parameter int WBYTES = 4,          // max bytes pushed/popped per cycle (= BPB)
    parameter int DEPTH  = 64          // total capacity in bytes (power of two)
)(
    input  wire                          clk,
    input  wire                          rstn,
    input  wire                          flush,      // synchronous clear

    // push (write side fills with up to WBYTES lane-compacted bytes)
    input  wire                          push_en,
    input  wire [$clog2(WBYTES+1)-1:0]   push_n,
    input  wire [WBYTES*8-1:0]           push_data,

    // pop (consumer takes up to WBYTES front bytes; pop_data is a peek)
    input  wire                          pop_en,
    input  wire [$clog2(WBYTES+1)-1:0]   pop_n,
    output wire [WBYTES*8-1:0]           pop_data,

    output wire [$clog2(DEPTH+1)-1:0]    count       // bytes currently stored
);
    localparam int PW = $clog2(DEPTH);

    logic [7:0]   mem [0:DEPTH-1];
    logic [PW:0]  wptr, rptr;

    assign count = wptr - rptr;

    // peek the WBYTES oldest bytes (byte 0 = oldest)
    genvar gi;
    generate for (gi = 0; gi < WBYTES; gi = gi + 1) begin : g_peek
        assign pop_data[gi*8 +: 8] = mem[(rptr[PW-1:0] + gi) & (DEPTH-1)];
    end endgenerate

    integer i;
    always_ff @(posedge clk) begin
        if (!rstn || flush) begin
            wptr <= '0; rptr <= '0;
        end else begin
            if (push_en) begin
                for (i = 0; i < WBYTES; i = i + 1)
                    if (i < push_n)
                        mem[(wptr[PW-1:0] + i) & (DEPTH-1)] <= push_data[i*8 +: 8];
                wptr <= wptr + push_n;
            end
            if (pop_en) rptr <= rptr + pop_n;
        end
    end

endmodule

`default_nettype wire
