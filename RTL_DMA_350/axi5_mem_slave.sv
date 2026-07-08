//-----------------------------------------------------------------------------
// axi5_mem_slave.sv  (testbench model)
//
// AXI5 memory subordinate for the DMA-350 testbenches. Handles read (AR/R) and
// write (AW/W/B) concurrently on one port, echoes AxID on R/B (so the DMA-350
// arbitration node can route responses), honours AxSIZE for the per-beat
// address stride (so narrow / unaligned transfers are modelled), and uses WSTRB
// for byte-accurate writes. Single outstanding per direction — sufficient for
// the basic self-checking tests. Always responds OKAY, never poisons.
//
// Backing store: byte-addressed flat array, shared by reads and writes.
//-----------------------------------------------------------------------------
`default_nettype none

module axi5_mem_slave #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4,
    parameter int MEM_BYTES  = 1<<16
)(
    input  wire                      aclk,
    input  wire                      aresetn,

    // write address
    input  wire [ADDR_WIDTH-1:0]     awaddr,
    input  wire [7:0]                awlen,
    input  wire [2:0]                awsize,
    input  wire [1:0]                awburst,
    input  wire [ID_WIDTH-1:0]       awid,
    input  wire                      awvalid,
    output reg                       awready,
    // write data
    input  wire [DATA_WIDTH-1:0]     wdata,
    input  wire [DATA_WIDTH/8-1:0]   wstrb,
    input  wire                      wlast,
    input  wire                      wvalid,
    output reg                       wready,
    // write response
    output reg  [1:0]                bresp,
    output reg  [ID_WIDTH-1:0]       bid,
    output reg                       bvalid,
    input  wire                      bready,

    // read address
    input  wire [ADDR_WIDTH-1:0]     araddr,
    input  wire [7:0]                arlen,
    input  wire [2:0]                arsize,
    input  wire [1:0]                arburst,
    input  wire [ID_WIDTH-1:0]       arid,
    input  wire                      arvalid,
    output reg                       arready,
    // read data
    output reg  [DATA_WIDTH-1:0]     rdata,
    output reg  [1:0]                rresp,
    output reg  [ID_WIDTH-1:0]       rid,
    output reg                       rlast,
    output reg                       rpoison,
    output reg                       rvalid,
    input  wire                      rready
);
    localparam int BPB     = DATA_WIDTH/8;
    localparam int ADDRLSB = $clog2(BPB);
    localparam [ADDR_WIDTH-1:0] WMASK = ~((1<<ADDRLSB)-1);   // bus-word align mask

    logic [7:0] mem [0:MEM_BYTES-1];

    // ------------------------------------------------------------- WRITE
    typedef enum logic [1:0] {W_IDLE, W_DATA, W_RESP} wst_t;
    wst_t wst;
    logic [ADDR_WIDTH-1:0] waddr;
    logic [2:0]            wsz;
    logic [ID_WIDTH-1:0]   wid;
    logic [1:0]            wburst;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            wst<=W_IDLE; awready<=0; wready<=0; bvalid<=0; bresp<=0; bid<=0;
            waddr<=0; wsz<=0; wid<=0; wburst<=0;
        end else begin
            awready <= 1'b0;
            case (wst)
                W_IDLE: begin
                    wready<=0; bvalid<=0;
                    if (awvalid && !awready) begin
                        awready<=1'b1;
                        waddr <= awaddr; wsz<=awsize; wid<=awid; wburst<=awburst;
                        wst   <= W_DATA;
                    end
                end
                W_DATA: begin
                    wready <= 1'b1;
                    if (wvalid && wready) begin
                        for (int b=0; b<BPB; b++)
                            if (wstrb[b]) mem[(waddr & WMASK) + b] <= wdata[b*8 +: 8];
                        if (wburst != 2'b00)            // INCR advances; FIXED holds
                            waddr <= waddr + (1 << wsz);
                        if (wlast) begin wready<=0; wst<=W_RESP; end
                    end
                end
                W_RESP: begin
                    bvalid<=1'b1; bresp<=2'b00; bid<=wid;
                    if (bvalid && bready) begin bvalid<=0; wst<=W_IDLE; end
                end
                default: wst<=W_IDLE;
            endcase
        end
    end

    // ------------------------------------------------------------- READ
    typedef enum logic [1:0] {R_IDLE, R_DATA} rst_t;
    rst_t rst;
    logic [ADDR_WIDTH-1:0] raddr;
    logic [8:0]            rbeats;
    logic [2:0]            rsz;
    logic [ID_WIDTH-1:0]   rid_q;
    logic [1:0]            rburst;

    function automatic [DATA_WIDTH-1:0] word_at(input [ADDR_WIDTH-1:0] a);
        logic [DATA_WIDTH-1:0] w;
        for (int b=0; b<BPB; b++) w[b*8 +: 8] = mem[(a & WMASK) + b];
        return w;
    endfunction

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            rst<=R_IDLE; arready<=0; rvalid<=0; rlast<=0; rresp<=0; rpoison<=0;
            rdata<=0; rid<=0; raddr<=0; rbeats<=0; rsz<=0; rid_q<=0; rburst<=0;
        end else begin
            arready <= 1'b0; rpoison <= 1'b0;
            case (rst)
                R_IDLE: begin
                    rvalid<=0; rlast<=0;
                    if (arvalid && !arready) begin
                        arready<=1'b1;
                        raddr <= araddr; rbeats<=arlen+1; rsz<=arsize;
                        rid_q <= arid; rburst<=arburst;
                        rst   <= R_DATA;
                    end
                end
                R_DATA: begin
                    if (!rvalid) begin
                        rdata  <= word_at(raddr);
                        rresp  <= 2'b00; rid <= rid_q;
                        rvalid <= 1'b1;
                        rlast  <= (rbeats == 9'd1);
                    end else if (rvalid && rready) begin
                        if (rbeats == 9'd1) begin
                            rvalid<=0; rlast<=0; rst<=R_IDLE;
                        end else begin
                            logic [ADDR_WIDTH-1:0] na;
                            na     = (rburst!=2'b00) ? raddr + (1<<rsz) : raddr;
                            raddr  <= na;
                            rbeats <= rbeats - 1;
                            rdata  <= word_at(na);
                            rlast  <= (rbeats == 9'd2);
                        end
                    end
                end
                default: rst<=R_IDLE;
            endcase
        end
    end

    // ---- TB preload / check helpers ----
    task automatic write_byte(input int unsigned a, input logic [7:0] d);
        mem[a] = d;
    endtask
    function automatic logic [7:0] read_byte(input int unsigned a);
        return mem[a];
    endfunction

endmodule

`default_nettype wire
