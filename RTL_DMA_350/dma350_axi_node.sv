//-----------------------------------------------------------------------------
// dma350_axi_node.sv
//
// AXI5 manager arbitration node with configurable issuing capability.
// Multiplexes N per-channel read/write managers onto one physical AXI5 manager
// port (M0 or M1), modelling the DMA-350 "AXI bandwidth utilization" / issuing
// capability behaviour.
//
//  * Read bus: ARs from any channel are accepted back-to-back (no per-burst
//    lock) up to ISSUING_CAP outstanding; AxID carries the channel index and
//    returning R beats are routed to the owner by RID. Multiple reads from one
//    or several channels can be in flight simultaneously.
//  * Write bus: AWs are accepted (up to ISSUING_CAP) and the channel index of
//    each accepted AW is pushed into an order FIFO. W data is driven from the
//    channel at the FIFO head until WLAST, preserving AXI write-data ordering;
//    B responses are routed back by BID.
//  * Channel arbitration on AR/AW is CHPRIO-priority with round-robin tie-break.
//
// Assumes ID_WIDTH >= clog2(N) so the channel index fits the AXI ID.
//-----------------------------------------------------------------------------
`default_nettype none

module dma350_axi_node #(
    parameter int N           = 1,
    parameter int ADDR_WIDTH  = 32,
    parameter int DATA_WIDTH  = 32,
    parameter int ID_WIDTH    = 4,
    parameter int ARUSER_W    = 1,
    parameter int AWUSER_W    = 1,
    parameter int ISSUING_CAP = 4       // max outstanding transactions per dir.
)(
    input  wire                          clk,
    input  wire                          resetn,

    // per-channel priority (CHPRIO)
    input  wire [3:0]                    ch_prio     [N],

    // ---- per-channel read managers ----
    input  wire [N-1:0]                  ch_arvalid,
    output wire [N-1:0]                  ch_arready,
    input  wire [ADDR_WIDTH-1:0]         ch_araddr   [N],
    input  wire [7:0]                    ch_arlen    [N],
    input  wire [2:0]                    ch_arsize   [N],
    input  wire [1:0]                    ch_arburst  [N],
    input  wire [ARUSER_W-1:0]           ch_aruser   [N],
    output wire [N-1:0]                  ch_rvalid,
    input  wire [N-1:0]                  ch_rready,
    output wire [DATA_WIDTH-1:0]         ch_rdata,
    output wire [1:0]                    ch_rresp,
    output wire                          ch_rpoison,
    output wire                          ch_rlast,

    // ---- per-channel write managers ----
    input  wire [N-1:0]                  ch_awvalid,
    output wire [N-1:0]                  ch_awready,
    input  wire [ADDR_WIDTH-1:0]         ch_awaddr   [N],
    input  wire [7:0]                    ch_awlen    [N],
    input  wire [2:0]                    ch_awsize   [N],
    input  wire [1:0]                    ch_awburst  [N],
    input  wire [AWUSER_W-1:0]           ch_awuser   [N],
    input  wire [N-1:0]                  ch_wvalid,
    output wire [N-1:0]                  ch_wready,
    input  wire [DATA_WIDTH-1:0]         ch_wdata    [N],
    input  wire [DATA_WIDTH/8-1:0]       ch_wstrb    [N],
    input  wire [N-1:0]                  ch_wlast,
    output wire [N-1:0]                  ch_bvalid,
    input  wire [N-1:0]                  ch_bready,
    output wire [1:0]                    ch_bresp,

    // ---- physical AXI5 manager port ----
    output reg  [ADDR_WIDTH-1:0]         m_araddr,
    output reg  [7:0]                    m_arlen,
    output reg  [2:0]                    m_arsize,
    output reg  [1:0]                    m_arburst,
    output reg  [ID_WIDTH-1:0]           m_arid,
    output reg  [ARUSER_W-1:0]           m_aruser,
    output reg                           m_arvalid,
    input  wire                          m_arready,
    input  wire [DATA_WIDTH-1:0]         m_rdata,
    input  wire [1:0]                    m_rresp,
    input  wire                          m_rpoison,
    input  wire                          m_rlast,
    input  wire                          m_rvalid,
    input  wire [ID_WIDTH-1:0]           m_rid,
    output wire                          m_rready,

    output reg  [ADDR_WIDTH-1:0]         m_awaddr,
    output reg  [7:0]                    m_awlen,
    output reg  [2:0]                    m_awsize,
    output reg  [1:0]                    m_awburst,
    output reg  [ID_WIDTH-1:0]           m_awid,
    output reg  [AWUSER_W-1:0]           m_awuser,
    output reg                           m_awvalid,
    input  wire                          m_awready,
    output reg  [DATA_WIDTH-1:0]         m_wdata,
    output reg  [DATA_WIDTH/8-1:0]       m_wstrb,
    output reg                           m_wlast,
    output reg                           m_wvalid,
    input  wire                          m_wready,
    input  wire [1:0]                    m_bresp,
    input  wire                          m_bvalid,
    input  wire [ID_WIDTH-1:0]           m_bid,
    output wire                          m_bready
);
    localparam int IDXW = (N <= 1) ? 1 : $clog2(N);
    localparam int CAPW = $clog2(ISSUING_CAP+1);
    localparam [N-1:0] ONEHOT = {{(N-1){1'b0}}, 1'b1};

    // index of the channel that owns an incoming R/B by its returned ID
    wire [IDXW-1:0] r_idx = m_rid[IDXW-1:0];
    wire [IDXW-1:0] b_idx = m_bid[IDXW-1:0];

    // CHPRIO-priority rotating selector
    function automatic [IDXW-1:0] pick(input [N-1:0] req, input [IDXW-1:0] ptr);
        logic [IDXW-1:0] best; logic [3:0] best_pri; logic found;
        best = ptr; best_pri = 4'd0; found = 1'b0;
        for (int k = 0; k < N; k++) begin
            int j = (ptr + k) % N;
            if (req[j]) begin
                if (!found || ch_prio[j] > best_pri) begin
                    best = j[IDXW-1:0]; best_pri = ch_prio[j]; found = 1'b1;
                end
            end
        end
        return best;
    endfunction

    // =====================================================================
    // Read: accept ARs up to ISSUING_CAP outstanding, route R by RID
    // =====================================================================
    reg  [CAPW-1:0]  rd_out;          // outstanding read bursts
    reg  [IDXW-1:0]  read_ptr;
    reg              ar_lock;         // hold grant stable while ARVALID & !READY
    reg  [IDXW-1:0]  ar_sel_q;
    wire [IDXW-1:0]  ar_pick   = pick(ch_arvalid, read_ptr);
    wire [IDXW-1:0]  rgrant    = ar_lock ? ar_sel_q : ar_pick;
    wire             rd_cap_ok = (rd_out < ISSUING_CAP[CAPW-1:0]);

    always_comb begin
        m_araddr  = ch_araddr[rgrant];
        m_arlen   = ch_arlen[rgrant];
        m_arsize  = ch_arsize[rgrant];
        m_arburst = ch_arburst[rgrant];
        m_aruser  = ch_aruser[rgrant];
        m_arid    = {{(ID_WIDTH-IDXW){1'b0}}, rgrant};
        m_arvalid = ch_arvalid[rgrant] & rd_cap_ok;
    end
    assign ch_arready = (m_arvalid & m_arready) ? (ONEHOT << rgrant) : '0;

    // R routing by ID (broadcast data, one-hot valid)
    assign ch_rdata   = m_rdata;
    assign ch_rresp   = m_rresp;
    assign ch_rpoison = m_rpoison;
    assign ch_rlast   = m_rlast;
    assign ch_rvalid  = m_rvalid ? (ONEHOT << r_idx) : '0;
    assign m_rready   = ch_rready[r_idx];

    wire ar_fire = m_arvalid & m_arready;
    wire r_done  = m_rvalid  & m_rready & m_rlast;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            rd_out <= '0; read_ptr <= '0; ar_lock <= 1'b0; ar_sel_q <= '0;
        end else begin
            if (ar_fire) begin
                ar_lock  <= 1'b0;
                read_ptr <= (rgrant + 1) % N;
            end else if (m_arvalid) begin       // presented, not yet accepted
                ar_lock  <= 1'b1;
                ar_sel_q <= rgrant;
            end
            case ({ar_fire, r_done})
                2'b10: rd_out <= rd_out + 1'b1;
                2'b01: rd_out <= rd_out - 1'b1;
                default: ;                       // 2'b11 / 2'b00: no net change
            endcase
        end
    end

    // =====================================================================
    // Write: accept AWs up to ISSUING_CAP, order FIFO for W, route B by BID
    // =====================================================================
    reg  [CAPW-1:0]  wr_out;          // outstanding write bursts (AW..B)
    reg  [IDXW-1:0]  write_ptr;
    reg              aw_lock;         // hold grant stable while AWVALID & !READY
    reg  [IDXW-1:0]  aw_sel_q;
    wire [IDXW-1:0]  aw_pick  = pick(ch_awvalid, write_ptr);
    wire [IDXW-1:0]  wgrant   = aw_lock ? aw_sel_q : aw_pick;

    // AW-order FIFO of channel indices (W data must follow AW order)
    reg  [IDXW-1:0]  oq_id   [ISSUING_CAP];
    reg  [CAPW-1:0]  oq_cnt;
    reg  [CAPW-1:0]  oq_head, oq_tail;
    wire             oq_empty = (oq_cnt == 0);
    wire             oq_full  = (oq_cnt == ISSUING_CAP[CAPW-1:0]);
    wire [IDXW-1:0]  w_owner  = oq_id[oq_head];

    wire aw_can = (wr_out < ISSUING_CAP[CAPW-1:0]) & ~oq_full;

    always_comb begin
        m_awaddr  = ch_awaddr[wgrant];
        m_awlen   = ch_awlen[wgrant];
        m_awsize  = ch_awsize[wgrant];
        m_awburst = ch_awburst[wgrant];
        m_awuser  = ch_awuser[wgrant];
        m_awid    = {{(ID_WIDTH-IDXW){1'b0}}, wgrant};
        m_awvalid = ch_awvalid[wgrant] & aw_can;
    end
    assign ch_awready = (m_awvalid & m_awready) ? (ONEHOT << wgrant) : '0;

    // W from the order-FIFO head owner; the owner delimits its burst with WLAST
    always_comb begin
        m_wdata  = ch_wdata[w_owner];
        m_wstrb  = ch_wstrb[w_owner];
        m_wlast  = ch_wlast[w_owner];
        m_wvalid = ~oq_empty & ch_wvalid[w_owner];
    end
    assign ch_wready = (~oq_empty & m_wready) ? (ONEHOT << w_owner) : '0;

    // B routing by ID
    assign m_bready  = ch_bready[b_idx];
    assign ch_bresp  = m_bresp;
    assign ch_bvalid = m_bvalid ? (ONEHOT << b_idx) : '0;

    wire aw_fire = m_awvalid & m_awready;
    wire w_fire  = m_wvalid  & m_wready;
    wire w_pop   = w_fire & m_wlast;          // head burst finished
    wire b_fire  = m_bvalid & m_bready;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            wr_out<=0; write_ptr<=0; oq_cnt<=0; oq_head<=0; oq_tail<=0;
            aw_lock<=1'b0; aw_sel_q<=0;
        end else begin
            // ---- AW grant lock (hold stable while AWVALID & !AWREADY) ----
            if (aw_fire)        aw_lock <= 1'b0;
            else if (m_awvalid) begin aw_lock <= 1'b1; aw_sel_q <= wgrant; end

            // ---- AW accept: push owner to the order FIFO ----
            if (aw_fire) begin
                oq_id[oq_tail] <= wgrant;
                oq_tail        <= (oq_tail + 1) % ISSUING_CAP;
                write_ptr      <= (wgrant + 1) % N;
            end
            // ---- W last beat: pop the head ----
            if (w_pop) oq_head <= (oq_head + 1) % ISSUING_CAP;

            // ---- order-FIFO occupancy ----
            case ({aw_fire, w_pop})
                2'b10: oq_cnt <= oq_cnt + 1'b1;
                2'b01: oq_cnt <= oq_cnt - 1'b1;
                default: ;
            endcase
            // ---- outstanding write count (AW..B) ----
            case ({aw_fire, b_fire})
                2'b10: wr_out <= wr_out + 1'b1;
                2'b01: wr_out <= wr_out - 1'b1;
                default: ;
            endcase
        end
    end

endmodule

`default_nettype wire
