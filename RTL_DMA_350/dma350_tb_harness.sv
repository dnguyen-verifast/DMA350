//-----------------------------------------------------------------------------
// dma350_tb_harness.sv  (testbench harness)
//
// Wraps dma350_top with one AXI5 memory subordinate on the M0 port (shared by
// reads and writes) and ties off every sideband interface that the basic
// self-checking tests do not exercise (M1, Q/P-Channel, triggers, stream,
// all-channel stop/pause, CTI, boot). Exposes the APB4 control port and the
// channel interrupts; the backing memory is reachable as <inst>.u_mem.
//-----------------------------------------------------------------------------
`default_nettype none

module dma350_tb_harness #(
    parameter int ADDR_WIDTH   = 32,
    parameter int DATA_WIDTH   = 32,
    parameter int ID_WIDTH     = 4,
    parameter int NUM_CHANNELS = 1,
    parameter int MEM_BYTES    = 1<<16
)(
    input  wire                         clk,
    input  wire                         resetn,

    // APB4 control
    input  wire                         psel,
    input  wire                         penable,
    input  wire                         pwrite,
    input  wire [12:0]                  paddr,
    input  wire [31:0]                  pwdata,
    input  wire [3:0]                   pstrb,
    output wire [31:0]                  prdata,
    output wire                         pready,
    output wire                         pslverr,

    output wire [NUM_CHANNELS-1:0]      irq_channel,
    output wire                         irq_comb_nonsec,
    output wire                         irq_comb_sec
);
    localparam int STRB_W = DATA_WIDTH/8;

    // ---- M0 wires (top <-> memory) ----
    wire                  awvalid, awready, wvalid, wready, bvalid, bready;
    wire [ADDR_WIDTH-1:0] awaddr;  wire [7:0] awlen; wire [2:0] awsize;
    wire [1:0]            awburst; wire [ID_WIDTH-1:0] awid;
    wire [DATA_WIDTH-1:0] wdata;   wire [STRB_W-1:0] wstrb; wire wlast;
    wire [1:0]            bresp;   wire [ID_WIDTH-1:0] bid;
    wire                  arvalid, arready, rvalid, rready, rlast, rpoison;
    wire [ADDR_WIDTH-1:0] araddr;  wire [7:0] arlen; wire [2:0] arsize;
    wire [1:0]            arburst; wire [ID_WIDTH-1:0] arid;
    wire [DATA_WIDTH-1:0] rdata;   wire [1:0] rresp; wire [ID_WIDTH-1:0] rid;

    // ---- stream tie-off ----
    localparam int NC = NUM_CHANNELS;
    
    dma350_top #(
        .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH),
        .CHID_WIDTH(0), .POIS_WIDTH(1), .NUM_CHANNELS(NUM_CHANNELS),
        .AXI5_M1_PRESENT(0), .SECEXT_PRESENT(1),
        .NUM_TRIGGER_IN(4), .NUM_TRIGGER_OUT(4), .GPO_WIDTH(4),
        .FIFO_DEPTH(16), .BURST_SIZE(16), .ISSUING_CAP(8), .AWQ_DEPTH(4)
    ) dut (
        .clk(clk), .resetn(resetn),
        .aclken_m0(1'b1), .aclken_m1(1'b1), .pclken(1'b1),

        // Q-Channel: no quiescence request
        .clk_qreqn(1'b1), .clk_qacceptn(), .clk_qdeny(), .clk_qactive(),
        // P-Channel: no power request
        .preq(1'b0), .pstate(4'h8), .paccept(), .pdeny(), .pactive(),

        // APB4 (pprot = privileged, Secure: channels default to privileged)
        .psel(psel), .penable(penable), .pprot(3'b001), .pwrite(pwrite),
        .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
        .pready(pready), .pslverr(pslverr), .prdata(prdata),
        .pwakeup(1'b0), .pdebug(1'b0),

        // AXI5 M0
        .awakeup_m0(), .awvalid_m0(awvalid), .awready_m0(awready),
        .awaddr_m0(awaddr), .awburst_m0(awburst), .awid_m0(awid),
        .awlen_m0(awlen), .awsize_m0(awsize), .awqos_m0(), .awprot_m0(),
        .awcache_m0(), .awdomain_m0(), .awinner_m0(), .awchid_m0(),
        .awchidvalid_m0(),
        .arvalid_m0(arvalid), .arready_m0(arready), .araddr_m0(araddr),
        .arburst_m0(arburst), .arid_m0(arid), .arlen_m0(arlen),
        .arsize_m0(arsize), .arqos_m0(), .arprot_m0(), .arcache_m0(),
        .ardomain_m0(), .arinner_m0(), .archid_m0(), .archidvalid_m0(),
        .arcmdlink_m0(),
        .wvalid_m0(wvalid), .wready_m0(wready), .wlast_m0(wlast),
        .wstrb_m0(wstrb), .wdata_m0(wdata),
        .rvalid_m0(rvalid), .rready_m0(rready), .rid_m0(rid), .rlast_m0(rlast),
        .rdata_m0(rdata), .rpoison_m0(rpoison), .rresp_m0(rresp),
        .bvalid_m0(bvalid), .bready_m0(bready), .bid_m0(bid), .bresp_m0(bresp),

        // AXI5 M1 (unused: inputs held inactive, outputs open)
        .awakeup_m1(), .awvalid_m1(), .awready_m1(1'b0), .awaddr_m1(),
        .awburst_m1(), .awid_m1(), .awlen_m1(), .awsize_m1(), .awqos_m1(),
        .awprot_m1(), .awcache_m1(), .awdomain_m1(), .awinner_m1(),
        .awchid_m1(), .awchidvalid_m1(),
        .arvalid_m1(), .arready_m1(1'b0), .araddr_m1(), .arburst_m1(),
        .arid_m1(), .arlen_m1(), .arsize_m1(), .arqos_m1(), .arprot_m1(),
        .arcache_m1(), .ardomain_m1(), .arinner_m1(), .archid_m1(),
        .archidvalid_m1(), .arcmdlink_m1(),
        .wvalid_m1(), .wready_m1(1'b0), .wlast_m1(), .wstrb_m1(), .wdata_m1(),
        .rvalid_m1(1'b0), .rready_m1(), .rid_m1({ID_WIDTH{1'b0}}), .rlast_m1(1'b0),
        .rdata_m1({DATA_WIDTH{1'b0}}), .rpoison_m1(1'b0), .rresp_m1(2'b00),
        .bvalid_m1(1'b0), .bready_m1(), .bid_m1({ID_WIDTH{1'b0}}), .bresp_m1(2'b00),

        // Trigger (idle)
        .trig_in_req(4'b0), .trig_in_req_type(8'b0),
        .trig_in_ack(), .trig_in_ack_type(),
        .trig_out_req(), .trig_out_ack(4'b0),

        // IRQ
        .irq_channel(irq_channel), .irq_comb_nonsec(irq_comb_nonsec),
        .irq_comb_sec(irq_comb_sec), .irq_sec_viol_err(),

        // Stream (DPU absent: out ready low, in idle)
        .str_out_tvalid(), .str_out_tready({NC{1'b0}}), .str_out_tdata(),
        .str_out_tstrb(), .str_out_tlast(),
        .str_in_tvalid({NC{1'b0}}), .str_in_tready(),
        .str_in_tdata({NC*DATA_WIDTH{1'b0}}), .str_in_tstrb({NC*STRB_W{1'b0}}),
        .str_in_tlast({NC{1'b0}}), .str_in_flush(),

        // Status / control (idle)
        .gpo_ch(),
        .allch_stop_req_nonsec(1'b0), .allch_stop_ack_nonsec(),
        .allch_pause_req_nonsec(1'b0), .allch_pause_ack_nonsec(),
        .allch_stop_req_sec(1'b0), .allch_stop_ack_sec(),
        .allch_pause_req_sec(1'b0), .allch_pause_ack_sec(),
        .halt_req(1'b0), .restart_req(1'b0), .halted(),
        .ch_enabled(), .ch_err(), .ch_stopped(), .ch_paused(),
        .ch_priv(), .ch_nonsec(),

        // Config (boot disabled)
        .boot_en(1'b0), .boot_addr({(ADDR_WIDTH-2){1'b0}}),
        .boot_memattr(8'b0), .boot_shareattr(2'b0)
    );

    axi5_mem_slave #(
        .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH),
        .MEM_BYTES(MEM_BYTES)
    ) u_mem (
        .aclk(clk), .aresetn(resetn),
        .awaddr(awaddr), .awlen(awlen), .awsize(awsize), .awburst(awburst),
        .awid(awid), .awvalid(awvalid), .awready(awready),
        .wdata(wdata), .wstrb(wstrb), .wlast(wlast), .wvalid(wvalid),
        .wready(wready), .bresp(bresp), .bid(bid), .bvalid(bvalid), .bready(bready),
        .araddr(araddr), .arlen(arlen), .arsize(arsize), .arburst(arburst),
        .arid(arid), .arvalid(arvalid), .arready(arready),
        .rdata(rdata), .rresp(rresp), .rid(rid), .rlast(rlast),
        .rpoison(rpoison), .rvalid(rvalid), .rready(rready)
    );

endmodule

`default_nettype wire
