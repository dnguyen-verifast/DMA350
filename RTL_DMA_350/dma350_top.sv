//-----------------------------------------------------------------------------
// dma350_top.sv
//
// Arm CoreLink DMA-350 Controller top level. The port list mirrors the full
// signal set of TRM Appendix A "Signal descriptions" (Tables A-1 .. A-11):
//
//   A-1  Clock and reset      clk, resetn, aclken_m0/m1, pclken
//   A-2  Q-Channel (clock)    clk_qreqn/qacceptn/qdeny/qactive
//   A-3  P-Channel (power)    preq/pstate/paccept/pdeny/pactive
//   A-4  APB4                 psel..prdata, pwakeup, pdebug
//   A-5  AXI5 M0              full AW/AR/W/R/B + user (cache/domain/qos/prot/
//                             chid/chidvalid/cmdlink/poison)
//   A-6  AXI5 M1              same, active when AXI5_M1_PRESENT
//   A-7  Trigger              trig_in_* / trig_out_*  (flattened per port)
//   A-8  IRQ                  irq_channel, irq_comb_nonsec/sec, irq_sec_viol_err
//   A-9  Stream               str_out_* / str_in_*    (flattened per channel)
//   A-10 Status/Control       gpo, allch stop/pause, halt/restart, ch_* status
//   A-11 Config               boot_en/boot_addr/boot_memattr/boot_shareattr
//
// Per-port / per-channel buses that the spec names individually (e.g.
// trig_in_<TI>_req, str_out_<N>_tdata) are exposed as flattened packed vectors;
// index <i> maps to bit i (scalars) or lanes [i*W +: W] (buses).
//
// Architecture: NUM_CHANNELS command engines (dma350_channel) each with a
// DMACH<n> register frame (dma350_ch_regs), multiplexed onto the AXI5 manager
// port(s) by dma350_axi_node. Sideband: Q/P-Channel LPI, trigger handshakes,
// IRQ aggregation, all-channel stop/pause and CTI halt/restart, boot loader.
//-----------------------------------------------------------------------------
`default_nettype none

module dma350_top import dma350_pkg::*; #(
    parameter int ADDR_WIDTH      = 32,
    parameter int DATA_WIDTH      = 32,
    parameter int ID_WIDTH        = 4,
    parameter int CHID_WIDTH      = 0,
    parameter int POIS_WIDTH      = 1,
    parameter int NUM_CHANNELS    = 4,
    parameter int AXI5_M1_PRESENT = 0,
    // Per-channel manager assignment: bit g = 1 routes channel g's read AND
    // write to manager M1, 0 to M0 (DMA-350 assigns a whole channel to one
    // manager, it does NOT split read/write across ports). Ignored unless
    // AXI5_M1_PRESENT. Default: all channels on M0.
    parameter [31:0] CH_MGR_SEL   = 32'h0,
    // Opt-in load spreading: when 1 (and M1 present), channel g is auto-assigned
    // to manager g[0] (even->M0, odd->M1) instead of using CH_MGR_SEL, so
    // multiple channels naturally use both ports. Default off (use CH_MGR_SEL).
    parameter int MGR_AUTO_SPREAD = 0,
    parameter int SECEXT_PRESENT  = 1,
    parameter int NUM_TRIGGER_IN  = 4,
    parameter int NUM_TRIGGER_OUT = 4,
    parameter int GPO_WIDTH       = 4,
    parameter int FIFO_DEPTH      = 16,
    parameter int BURST_SIZE      = 16,
    parameter int ISSUING_CAP     = 8,   // max outstanding AXI transactions / port
    parameter int AWQ_DEPTH       = 4    // per-channel write-burst issuing depth
)(
    // ---- A-1 Clock and reset ----
    input  wire                          clk,
    input  wire                          resetn,
    input  wire                          aclken_m0,
    input  wire                          aclken_m1,
    input  wire                          pclken,

    // ---- A-2 Q-Channel (clock LPI) ----
    input  wire                          clk_qreqn,
    output wire                          clk_qacceptn,
    output wire                          clk_qdeny,
    output wire                          clk_qactive,

    // ---- A-3 P-Channel (power LPI) ----
    input  wire                          preq,
    input  wire [3:0]                    pstate,
    output wire                          paccept,
    output wire                          pdeny,
    output wire [9:0]                    pactive,

    // ---- A-4 APB4 ----
    input  wire                          psel,
    input  wire                          penable,
    input  wire [2:0]                    pprot,
    input  wire                          pwrite,
    input  wire [12:0]                   paddr,
    input  wire [31:0]                   pwdata,
    input  wire [3:0]                    pstrb,
    output wire                          pready,
    output wire                          pslverr,
    output wire [31:0]                   prdata,
    input  wire                          pwakeup,
    input  wire                          pdebug,

    // ---- A-5 AXI5 M0 ----
    output wire                          awakeup_m0,
    output wire                          awvalid_m0,
    input  wire                          awready_m0,
    output wire [ADDR_WIDTH-1:0]         awaddr_m0,
    output wire [1:0]                    awburst_m0,
    output wire [ID_WIDTH-1:0]           awid_m0,
    output wire [7:0]                    awlen_m0,
    output wire [2:0]                    awsize_m0,
    output wire [3:0]                    awqos_m0,
    output wire [2:0]                    awprot_m0,
    output wire [3:0]                    awcache_m0,
    output wire [1:0]                    awdomain_m0,
    output wire [3:0]                    awinner_m0,
    output wire [((CHID_WIDTH<=0)?1:CHID_WIDTH)-1:0] awchid_m0,
    output wire                          awchidvalid_m0,
    output wire                          arvalid_m0,
    input  wire                          arready_m0,
    output wire [ADDR_WIDTH-1:0]         araddr_m0,
    output wire [1:0]                    arburst_m0,
    output wire [ID_WIDTH-1:0]           arid_m0,
    output wire [7:0]                    arlen_m0,
    output wire [2:0]                    arsize_m0,
    output wire [3:0]                    arqos_m0,
    output wire [2:0]                    arprot_m0,
    output wire [3:0]                    arcache_m0,
    output wire [1:0]                    ardomain_m0,
    output wire [3:0]                    arinner_m0,
    output wire [((CHID_WIDTH<=0)?1:CHID_WIDTH)-1:0] archid_m0,
    output wire                          archidvalid_m0,
    output wire                          arcmdlink_m0,
    output wire                          wvalid_m0,
    input  wire                          wready_m0,
    output wire                          wlast_m0,
    output wire [DATA_WIDTH/8-1:0]       wstrb_m0,
    output wire [DATA_WIDTH-1:0]         wdata_m0,
    input  wire                          rvalid_m0,
    output wire                          rready_m0,
    input  wire [ID_WIDTH-1:0]           rid_m0,
    input  wire                          rlast_m0,
    input  wire [DATA_WIDTH-1:0]         rdata_m0,
    input  wire [((POIS_WIDTH<=0)?1:POIS_WIDTH)-1:0] rpoison_m0,
    input  wire [1:0]                    rresp_m0,
    input  wire                          bvalid_m0,
    output wire                          bready_m0,
    input  wire [ID_WIDTH-1:0]           bid_m0,
    input  wire [1:0]                    bresp_m0,

    // ---- A-6 AXI5 M1 (active when AXI5_M1_PRESENT) ----
    output wire                          awakeup_m1,
    output wire                          awvalid_m1,
    input  wire                          awready_m1,
    output wire [ADDR_WIDTH-1:0]         awaddr_m1,
    output wire [1:0]                    awburst_m1,
    output wire [ID_WIDTH-1:0]           awid_m1,
    output wire [7:0]                    awlen_m1,
    output wire [2:0]                    awsize_m1,
    output wire [3:0]                    awqos_m1,
    output wire [2:0]                    awprot_m1,
    output wire [3:0]                    awcache_m1,
    output wire [1:0]                    awdomain_m1,
    output wire [3:0]                    awinner_m1,
    output wire [((CHID_WIDTH<=0)?1:CHID_WIDTH)-1:0] awchid_m1,
    output wire                          awchidvalid_m1,
    output wire                          arvalid_m1,
    input  wire                          arready_m1,
    output wire [ADDR_WIDTH-1:0]         araddr_m1,
    output wire [1:0]                    arburst_m1,
    output wire [ID_WIDTH-1:0]           arid_m1,
    output wire [7:0]                    arlen_m1,
    output wire [2:0]                    arsize_m1,
    output wire [3:0]                    arqos_m1,
    output wire [2:0]                    arprot_m1,
    output wire [3:0]                    arcache_m1,
    output wire [1:0]                    ardomain_m1,
    output wire [3:0]                    arinner_m1,
    output wire [((CHID_WIDTH<=0)?1:CHID_WIDTH)-1:0] archid_m1,
    output wire                          archidvalid_m1,
    output wire                          arcmdlink_m1,
    output wire                          wvalid_m1,
    input  wire                          wready_m1,
    output wire                          wlast_m1,
    output wire [DATA_WIDTH/8-1:0]       wstrb_m1,
    output wire [DATA_WIDTH-1:0]         wdata_m1,
    input  wire                          rvalid_m1,
    output wire                          rready_m1,
    input  wire [ID_WIDTH-1:0]           rid_m1,
    input  wire                          rlast_m1,
    input  wire [DATA_WIDTH-1:0]         rdata_m1,
    input  wire [((POIS_WIDTH<=0)?1:POIS_WIDTH)-1:0] rpoison_m1,
    input  wire [1:0]                    rresp_m1,
    input  wire                          bvalid_m1,
    output wire                          bready_m1,
    input  wire [ID_WIDTH-1:0]           bid_m1,
    input  wire [1:0]                    bresp_m1,

    // ---- A-7 Trigger (flattened: index i -> bit i / lanes [2i+:2]) ----
    input  wire [NUM_TRIGGER_IN-1:0]     trig_in_req,
    input  wire [2*NUM_TRIGGER_IN-1:0]   trig_in_req_type,
    output wire [NUM_TRIGGER_IN-1:0]     trig_in_ack,
    output wire [2*NUM_TRIGGER_IN-1:0]   trig_in_ack_type,
    output wire [NUM_TRIGGER_OUT-1:0]    trig_out_req,
    input  wire [NUM_TRIGGER_OUT-1:0]    trig_out_ack,

    // ---- A-8 IRQ ----
    output wire [NUM_CHANNELS-1:0]       irq_channel,
    output wire                          irq_comb_nonsec,
    output wire                          irq_comb_sec,
    output wire                          irq_sec_viol_err,

    // ---- A-9 Stream (flattened per channel) ----
    output wire [NUM_CHANNELS-1:0]       str_out_tvalid,
    input  wire [NUM_CHANNELS-1:0]       str_out_tready,
    output wire [NUM_CHANNELS*DATA_WIDTH-1:0]   str_out_tdata,
    output wire [NUM_CHANNELS*(DATA_WIDTH/8)-1:0] str_out_tstrb,
    output wire [NUM_CHANNELS-1:0]       str_out_tlast,
    input  wire [NUM_CHANNELS-1:0]       str_in_tvalid,
    output wire [NUM_CHANNELS-1:0]       str_in_tready,
    input  wire [NUM_CHANNELS*DATA_WIDTH-1:0]   str_in_tdata,
    input  wire [NUM_CHANNELS*(DATA_WIDTH/8)-1:0] str_in_tstrb,
    input  wire [NUM_CHANNELS-1:0]       str_in_tlast,
    output wire [NUM_CHANNELS-1:0]       str_in_flush,

    // ---- A-10 Status / Control ----
    output wire [NUM_CHANNELS*GPO_WIDTH-1:0] gpo_ch,
    input  wire                          allch_stop_req_nonsec,
    output wire                          allch_stop_ack_nonsec,
    input  wire                          allch_pause_req_nonsec,
    output wire                          allch_pause_ack_nonsec,
    input  wire                          allch_stop_req_sec,
    output wire                          allch_stop_ack_sec,
    input  wire                          allch_pause_req_sec,
    output wire                          allch_pause_ack_sec,
    input  wire                          halt_req,
    input  wire                          restart_req,
    output wire                          halted,
    output wire [NUM_CHANNELS-1:0]       ch_enabled,
    output wire [NUM_CHANNELS-1:0]       ch_err,
    output wire [NUM_CHANNELS-1:0]       ch_stopped,
    output wire [NUM_CHANNELS-1:0]       ch_paused,
    output wire [NUM_CHANNELS-1:0]       ch_priv,
    output wire [NUM_CHANNELS-1:0]       ch_nonsec,

    // ---- A-11 Config ----
    input  wire                          boot_en,
    input  wire [ADDR_WIDTH-1:2]         boot_addr,
    input  wire [7:0]                    boot_memattr,
    input  wire [1:0]                    boot_shareattr
);
    localparam int NC      = NUM_CHANNELS;
    localparam int STRB_W  = DATA_WIDTH/8;
    localparam int CHIDNZ  = (CHID_WIDTH <= 0) ? 1 : CHID_WIDTH;
    localparam int ARUSER_W = 18 + CHIDNZ;   // prot,cache,domain,inner,qos,chid,cmdlink
    localparam int AWUSER_W = 17 + CHIDNZ;   // as above, no cmdlink

    genvar g;

    // forward-declared nets/regs referenced inside the channel generate block
    // and by the APB permission / read-mux logic (declared ahead of first
    // reference for strict declaration-order tools such as Questa vlog)
    logic [31:0]  ch_prdata  [NUM_CHANNELS];
    logic [NUM_CHANNELS-1:0] ch_pslverr;
    reg           boot_pulse;
    wire [NUM_CHANNELS-1:0] c_priv, c_nonsec;  // channel privilege/security ctx
    wire [31:0]   dma_lvl_rdata;               // DMA-unit frame read data
    reg           scfg_rsptype_q;              // SCFG_CTRL.RSPTYPE_SECACCVIO [1]

    // AXI user bundle pack helpers (declared before first use)
    function automatic [ARUSER_W-1:0] pack_aruser(
        input [2:0] prot, input [3:0] cache, input [1:0] domain,
        input [3:0] inner, input [3:0] qos, input [CHIDNZ-1:0] chid,
        input cmdlink);
        pack_aruser = {cmdlink, chid, qos, inner, domain, cache, prot};
    endfunction
    function automatic [AWUSER_W-1:0] pack_awuser(
        input [2:0] prot, input [3:0] cache, input [1:0] domain,
        input [3:0] inner, input [3:0] qos, input [CHIDNZ-1:0] chid);
        pack_awuser = {chid, qos, inner, domain, cache, prot};
    endfunction

    // =====================================================================
    // APB4 access phase + 1-wait-state PREADY
    // =====================================================================
    reg  pready_r;
    always_ff @(posedge clk)
        if (!resetn) pready_r <= 1'b0;
        else         pready_r <= psel & ~penable;   // assert in access phase
    assign pready = pready_r;

    // TRM 6.3 memory map: DMA channel <n> frame is at 0x1000 + 0x100*n
    // (paddr[12]=1, paddr[10:8]=n, paddr[7:0]=offset). The 0x0000-0x0FFF region
    // holds the DMA-unit frames (security/control/info).
    wire        apb_is_chan  = paddr[12];                  // channels at 0x1000+
    wire [3:0]  apb_chan_idx = {1'b0, paddr[10:8]};        // channel 0..7
    wire [7:0]  apb_off      = paddr[7:0];

    // ---- APB access permission (TRM 6.4 usage constraints, 4.2.1/4.2.3) ----
    // pprot[0] = privileged, pprot[1] = Non-secure. Blocked accesses read as
    // zero and writes are ignored (RAZ/WI); a security violation can instead
    // raise SLVERR when SCFG_CTRL.RSPTYPE_SECACCVIO is set, and it pulses the
    // violation interrupt - both suppressed for debugger accesses (pdebug).
    wire acc_ns      = pprot[1];
    wire acc_unpriv  = ~pprot[0];
    wire tgt_ch_ok   = apb_is_chan & (apb_chan_idx < NC[3:0]);
    wire ch_sec_viol  = (SECEXT_PRESENT != 0) & tgt_ch_ok & acc_ns
                      & ~c_nonsec[apb_chan_idx];
    wire ch_priv_viol = tgt_ch_ok & c_priv[apb_chan_idx] & acc_unpriv;
    // DMASECCFG (0x0) / DMASECCTRL (0x1) are Secure-privileged only;
    // DMANSECCTRL (0x2) is privileged only (TRM 6.4.2-6.4.4).
    wire unit_sec_viol  = (SECEXT_PRESENT != 0) & ~apb_is_chan & acc_ns
                        & ((paddr[11:8] == 4'h0) | (paddr[11:8] == 4'h1));
    wire unit_priv_viol = ~apb_is_chan & acc_unpriv
                        & ((paddr[11:8] == 4'h0) | (paddr[11:8] == 4'h1)
                           | (paddr[11:8] == 4'h2));
    wire apb_sec_viol = ch_sec_viol | unit_sec_viol;
    wire apb_blocked  = apb_sec_viol | ch_priv_viol | unit_priv_viol;

    // =====================================================================
    // Per-channel signal arrays
    // =====================================================================
    // command / status
    wire [NC-1:0] c_enablecmd, c_stopcmd, c_pausecmd, c_resumecmd;
    wire [NC-1:0] c_disablecmd, c_clearcmd, c_swtrigin_src, c_swtrigin_des;
    wire [NC-1:0] c_ch_enabled, c_done, c_stopped_p, c_disabled_p, c_error_p;
    wire [NC-1:0] c_paused, c_resumewait, c_srctrigwait, c_destrigwait, c_trigoutwait;
    wire [NC-1:0] c_clr_enablecmd, c_busy, c_irq;
    wire [NC-1:0] c_err_sticky;
    wire [31:0]   c_errinfo [NC];

    // config / attributes
    wire [ADDR_WIDTH-1:0] c_srcaddr [NC], c_desaddr [NC], c_linkaddr [NC];
    wire [31:0]  c_src_xsize [NC], c_des_xsize [NC];
    wire [2:0]   c_src_transize [NC], c_des_transize [NC];
    wire [NC-1:0] c_fill_en, c_wrap_en;
    wire [15:0]  c_ysize [NC];
    wire [ADDR_WIDTH-1:0] c_src_stride [NC], c_des_stride [NC];
    wire [31:0]  c_fillval [NC];
    wire signed [15:0] c_src_xaddrinc [NC], c_des_xaddrinc [NC];
    wire [31:0]  c_srctmplt [NC], c_destmplt [NC];
    wire [4:0]   c_srctmpltsize [NC], c_destmpltsize [NC];
    wire [2:0]   c_xtype [NC], c_ytype [NC], c_donetype [NC];
    wire [3:0]   c_chprio [NC];
    wire [NC-1:0] c_usestream, c_donepauseen, c_linkaddren, c_cmdrestartinfen;
    wire [2:0]   c_regreloadtype [NC];
    wire [15:0]  c_cmdrestartcnt [NC];
    wire [3:0]   c_src_cache [NC], c_des_cache [NC], c_src_inner [NC], c_des_inner [NC];
    wire [3:0]   c_src_maxburstlen [NC], c_des_maxburstlen [NC];
    wire [2:0]   c_src_prot [NC], c_des_prot [NC];
    wire [1:0]   c_src_domain [NC], c_des_domain [NC];
    wire [NC-1:0] c_srctrigin_en, c_destrigin_en, c_trigout_en;
    wire [7:0]   c_srctrigin_sel [NC], c_destrigin_sel [NC], c_trigout_sel [NC];
    wire [NC-1:0] c_srctrigin_hw, c_destrigin_hw, c_trigout_hw;
    wire [1:0]   c_srctrigin_mode [NC], c_destrigin_mode [NC];
    wire [7:0]   c_srctrigin_blksize [NC], c_destrigin_blksize [NC];
    wire [1:0]   c_swtrigin_srctype [NC], c_swtrigin_destype [NC];
    wire [NC-1:0] c_swtrigout_ack;
    wire [GPO_WIDTH-1:0] c_gpo_out [NC];
    // (c_priv / c_nonsec are forward-declared above, before the APB decode)

    // live / link write-back
    wire [NC-1:0] c_live_we;
    wire [ADDR_WIDTH-1:0] c_live_srcaddr [NC], c_live_desaddr [NC];
    wire [31:0]  c_live_src_xsize [NC], c_live_des_xsize [NC];
    wire [NC-1:0] c_iwr_en, c_iwr_regclear;
    wire [7:0]    c_iwr_off  [NC];
    wire [31:0]   c_iwr_data [NC];
    wire [ADDR_WIDTH-1:0] c_src_orig [NC], c_des_orig [NC];
    wire [31:0]  c_srcx_orig [NC], c_desx_orig [NC];

    // AXI read managers
    wire [NC-1:0]         c_arvalid, c_arready, c_rvalid, c_rready, c_arcmdlink;
    wire [ADDR_WIDTH-1:0] c_araddr [NC];
    wire [7:0]            c_arlen  [NC];
    wire [2:0]            c_arsize [NC];
    wire [1:0]            c_arburst [NC];
    wire [ARUSER_W-1:0]   c_aruser [NC];
    wire [DATA_WIDTH-1:0] c_rdata_m0, c_rdata_m1;
    wire [1:0]            c_rresp_m0, c_rresp_m1;
    wire                  c_rlast_m0, c_rlast_m1, c_rpoison_m0, c_rpoison_m1;

    // AXI write managers
    wire [NC-1:0]         c_awvalid, c_awready, c_wvalid, c_wready, c_bvalid, c_bready;
    wire [ADDR_WIDTH-1:0] c_awaddr [NC];
    wire [7:0]            c_awlen  [NC];
    wire [2:0]            c_awsize [NC];
    wire [1:0]            c_awburst [NC];
    wire [AWUSER_W-1:0]   c_awuser [NC];
    wire [DATA_WIDTH-1:0] c_wdata  [NC];
    wire [STRB_W-1:0]     c_wstrb  [NC];
    wire [NC-1:0]         c_wlast;
    wire [1:0]            c_bresp_m0, c_bresp_m1;

    // per-manager return handshakes (OR-combined into the channel-facing nets;
    // for any channel only the manager it is assigned to is ever active).
    wire [NC-1:0] arready0, arready1, rvalid0, rvalid1;
    wire [NC-1:0] awready0, awready1, wready0, wready1, bvalid0, bvalid1;
    // per-channel manager assignment (whole channel -> one manager, R+W both):
    // auto-spread by index if enabled, else the explicit CH_MGR_SEL bit; forced
    // to M0 when M1 is absent.
    wire [NC-1:0] mgr_vec;
    genvar gm;
    generate for (gm = 0; gm < NC; gm = gm + 1) begin : g_mgrsel
        assign mgr_vec[gm] = (AXI5_M1_PRESENT == 0) ? 1'b0
                           : (MGR_AUTO_SPREAD != 0)  ? gm[0]
                           :                           CH_MGR_SEL[gm];
    end endgenerate
    // fold the two managers' return handshakes back to the channel (per channel
    // exactly one manager is ever active, so OR is unambiguous).
    assign c_arready = arready0 | arready1;
    assign c_rvalid  = rvalid0  | rvalid1;
    assign c_awready = awready0 | awready1;
    assign c_wready  = wready0  | wready1;
    assign c_bvalid  = bvalid0  | bvalid1;

    // boot
    wire [NC-1:0] c_boot_req;
    wire [ADDR_WIDTH-1:0] boot_addr_full = {boot_addr, 2'b00};

    // trigger matrix nets
    wire [NUM_TRIGGER_IN-1:0]  ti_pending;
    wire [1:0]                 ti_type [NUM_TRIGGER_IN];
    wire [NUM_TRIGGER_IN-1:0]  ti_take;
    wire [NUM_TRIGGER_OUT-1:0] to_start, to_done;

    // per-channel trigger wiring
    wire [NC-1:0] c_src_trig_pending, c_des_trig_pending;
    wire [1:0]    c_src_trig_type [NC], c_des_trig_type [NC];
    wire [NC-1:0] c_src_trig_take, c_des_trig_take, c_trigout_start;
    wire [NC-1:0] c_src_trig_take_last, c_des_trig_take_last;
    wire [NC-1:0] c_trigout_done;
    // internal (channel-to-channel) trigger config + handshake (TRM 5.4.4)
    wire [NC-1:0] c_srctrigin_internal, c_destrigin_internal, c_trigout_internal;
    reg  [NC-1:0] int_req;              // sender s holds an internal trigout req
    wire [NC-1:0] int_ack;             // its target receiver took the trigger
    // trigger-port selection conflict / selector-range flags (per channel)
    wire [NC-1:0] c_srctrigin_sel_err, c_destrigin_sel_err, c_trigout_sel_err;
    wire [NC-1:0] c_trigsel_range_err;
    // trigger-in LAST OKAY acknowledge and SW deny (per external port)
    wire [NUM_TRIGGER_IN-1:0] ti_take_last;
    reg  [NUM_TRIGGER_IN-1:0] ti_deny;
    reg  [NUM_TRIGGER_IN-1:0] ti_selected;   // port owned by an enabled channel

    // per-channel SW CHID configuration (NSEC/SEC_CHCFG, stored in the unit
    // control frames below; declared here for use in the channel generate)
    reg  [15:0]   chid_q [NC];
    reg  [NC-1:0] chidvld_q;

    // P-Channel WARM_RST entry pauses all channels (TRM 5.9.1.1)
    wire pch_warm;

    // =====================================================================
    // Channel security context for all-channel and CTI controls. A P-Channel
    // WARM_RST request also pauses every channel (TRM 5.9.1.1).
    // =====================================================================
    wire [NC-1:0] sec_allstop  = ({NC{allch_stop_req_sec}}  & ~c_nonsec)
                               | ({NC{allch_stop_req_nonsec}} &  c_nonsec);
    wire [NC-1:0] sec_allpause = ({NC{allch_pause_req_sec}} & ~c_nonsec)
                               | ({NC{allch_pause_req_nonsec}} & c_nonsec)
                               | {NC{pch_warm}};

    // =====================================================================
    // Per-channel instantiation
    // =====================================================================
    generate for (g = 0; g < NC; g = g + 1) begin : g_ch
        // RAZ/WI enforcement: a blocked access never selects the channel frame
        wire ch_sel = psel & apb_is_chan & (apb_chan_idx == g) & ~apb_blocked;

        dma350_ch_regs #(
            .ADDR_WIDTH(ADDR_WIDTH), .GPO_WIDTH(GPO_WIDTH),
            .SECEXT_PRESENT(SECEXT_PRESENT),
            .BOOT_SECURE((g == 0) ? 1'b1 : 1'b0)
        ) u_regs (
            .pclk(clk), .presetn(resetn),
            .sel(ch_sel), .penable(penable), .pwrite(pwrite),
            .paddr(apb_off), .pwdata(pwdata), .pstrb(pstrb),
            .prdata(ch_prdata[g]), .pslverr(ch_pslverr[g]),
            .enablecmd(c_enablecmd[g]), .stopcmd(c_stopcmd[g]),
            .pausecmd(c_pausecmd[g]), .resumecmd(c_resumecmd[g]),
            .disablecmd(c_disablecmd[g]), .clearcmd(c_clearcmd[g]),
            .swtrigin_src(c_swtrigin_src[g]), .swtrigin_des(c_swtrigin_des[g]),
            .swtrigin_srctype(c_swtrigin_srctype[g]),
            .swtrigin_destype(c_swtrigin_destype[g]),
            .swtrigout_ack(c_swtrigout_ack[g]),
            .ch_enabled(c_ch_enabled[g]),
            .fsm_done(c_done[g]), .fsm_stopped(c_stopped_p[g]),
            .fsm_disabled(c_disabled_p[g]), .fsm_error(c_error_p[g]),
            .fsm_paused(c_paused[g]), .fsm_resumewait(c_resumewait[g]),
            .fsm_srctrigwait(c_srctrigwait[g]), .fsm_destrigwait(c_destrigwait[g]),
            .fsm_trigoutwait(c_trigoutwait[g]), .clr_enablecmd(c_clr_enablecmd[g]),
            .srcaddr(c_srcaddr[g]), .desaddr(c_desaddr[g]),
            .src_xsize(c_src_xsize[g]), .des_xsize(c_des_xsize[g]),
            .src_transize(c_src_transize[g]), .des_transize(c_des_transize[g]),
            .src_xaddrinc(c_src_xaddrinc[g]), .des_xaddrinc(c_des_xaddrinc[g]),
            .xtype(c_xtype[g]), .ytype(c_ytype[g]),
            .wrap_en(c_wrap_en[g]), .fill_en(c_fill_en[g]),
            .ysize(c_ysize[g]), .src_stride(c_src_stride[g]),
            .des_stride(c_des_stride[g]),
            .srctmplt(c_srctmplt[g]), .destmplt(c_destmplt[g]),
            .srctmpltsize(c_srctmpltsize[g]), .destmpltsize(c_destmpltsize[g]),
            .fillval(c_fillval[g]), .chprio(c_chprio[g]),
            .usestream(c_usestream[g]), .donepauseen(c_donepauseen[g]),
            .donetype(c_donetype[g]),
            .regreloadtype(c_regreloadtype[g]),
            .cmdrestartcnt(c_cmdrestartcnt[g]), .cmdrestartinfen(c_cmdrestartinfen[g]),
            .linkaddr(c_linkaddr[g]), .linkaddren(c_linkaddren[g]),
            .src_cache(c_src_cache[g]), .src_prot(c_src_prot[g]),
            .src_domain(c_src_domain[g]), .src_inner(c_src_inner[g]),
            .src_maxburstlen(c_src_maxburstlen[g]),
            .des_cache(c_des_cache[g]), .des_prot(c_des_prot[g]),
            .des_domain(c_des_domain[g]), .des_inner(c_des_inner[g]),
            .des_maxburstlen(c_des_maxburstlen[g]),
            .srctrigin_en(c_srctrigin_en[g]), .srctrigin_sel(c_srctrigin_sel[g]),
            .srctrigin_hw(c_srctrigin_hw[g]),
            .srctrigin_internal(c_srctrigin_internal[g]),
            .srctrigin_mode(c_srctrigin_mode[g]),
            .srctrigin_blksize(c_srctrigin_blksize[g]),
            .destrigin_en(c_destrigin_en[g]), .destrigin_sel(c_destrigin_sel[g]),
            .destrigin_hw(c_destrigin_hw[g]),
            .destrigin_internal(c_destrigin_internal[g]),
            .destrigin_mode(c_destrigin_mode[g]),
            .destrigin_blksize(c_destrigin_blksize[g]),
            .trigout_en(c_trigout_en[g]), .trigout_sel(c_trigout_sel[g]),
            .trigout_hw(c_trigout_hw[g]),
            .trigout_internal(c_trigout_internal[g]),
            .gpo_out(c_gpo_out[g]),
            .live_we(c_live_we[g]), .live_srcaddr(c_live_srcaddr[g]),
            .live_desaddr(c_live_desaddr[g]), .live_src_xsize(c_live_src_xsize[g]),
            .live_des_xsize(c_live_des_xsize[g]),
            .iwr_en(c_iwr_en[g]), .iwr_off(c_iwr_off[g]),
            .iwr_data(c_iwr_data[g]), .iwr_regclear(c_iwr_regclear[g]),
            .src_orig_o(c_src_orig[g]), .des_orig_o(c_des_orig[g]),
            .srcx_orig_o(c_srcx_orig[g]), .desx_orig_o(c_desx_orig[g]),
            .errinfo(c_errinfo[g]),
            .irq(c_irq[g])
        );

        dma350_channel #(
            .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
            .FIFO_DEPTH(FIFO_DEPTH), .BURST_SIZE(BURST_SIZE),
            .AWQ_DEPTH(AWQ_DEPTH)
        ) u_ch (
            .aclk(clk), .aresetn(resetn),
            .enablecmd(c_enablecmd[g]), .stopcmd(c_stopcmd[g]),
            .pausecmd(c_pausecmd[g]), .resumecmd(c_resumecmd[g]),
            .disablecmd(c_disablecmd[g]), .clearcmd(c_clearcmd[g]),
            .swtrigin_src(c_swtrigin_src[g]), .swtrigin_des(c_swtrigin_des[g]),
            .boot_req(c_boot_req[g]), .boot_addr_i(boot_addr_full),
            .halt_req(halt_req), .restart_req(restart_req),
            .allstop(sec_allstop[g]), .allpause(sec_allpause[g]),
            .ch_enabled(c_ch_enabled[g]),
            .fsm_done(c_done[g]), .fsm_stopped(c_stopped_p[g]),
            .fsm_disabled(c_disabled_p[g]), .fsm_error(c_error_p[g]),
            .fsm_paused(c_paused[g]), .fsm_resumewait(c_resumewait[g]),
            .fsm_srctrigwait(c_srctrigwait[g]), .fsm_destrigwait(c_destrigwait[g]),
            .fsm_trigoutwait(c_trigoutwait[g]), .clr_enablecmd(c_clr_enablecmd[g]),
            .busy(c_busy[g]), .errinfo(c_errinfo[g]),
            .srcaddr(c_srcaddr[g]), .desaddr(c_desaddr[g]),
            .src_xsize(c_src_xsize[g]), .des_xsize(c_des_xsize[g]),
            .src_transize(c_src_transize[g]), .des_transize(c_des_transize[g]),
            .src_xaddrinc(c_src_xaddrinc[g]), .des_xaddrinc(c_des_xaddrinc[g]),
            .ysize(c_ysize[g]), .src_stride(c_src_stride[g]),
            .des_stride(c_des_stride[g]),
            .wrap_en(c_wrap_en[g]), .fill_en(c_fill_en[g]),
            .fillval(c_fillval[g]),
            .srctmplt(c_srctmplt[g]), .destmplt(c_destmplt[g]),
            .srctmpltsize(c_srctmpltsize[g]), .destmpltsize(c_destmpltsize[g]),
            .usestream(c_usestream[g]),
            .xtype(c_xtype[g]), .donetype(c_donetype[g]),
            .regreloadtype(c_regreloadtype[g]),
            .donepauseen(c_donepauseen[g]),
            .cmdrestartcnt(c_cmdrestartcnt[g]), .cmdrestartinfen(c_cmdrestartinfen[g]),
            .linkaddr(c_linkaddr[g]), .linkaddren(c_linkaddren[g]),
            .srctrigin_en(c_srctrigin_en[g]),
            .srctrigin_mode(c_srctrigin_mode[g]),
            .src_trigin_blksize(c_srctrigin_blksize[g]),
            .destrigin_en(c_destrigin_en[g]),
            .destrigin_mode(c_destrigin_mode[g]),
            .des_trigin_blksize(c_destrigin_blksize[g]),
            .trigout_en(c_trigout_en[g]),
            .swtrigin_srctype(c_swtrigin_srctype[g]),
            .swtrigin_destype(c_swtrigin_destype[g]),
            .swtrigout_ack(c_swtrigout_ack[g]),
            .src_maxburstlen(c_src_maxburstlen[g]),
            .des_maxburstlen(c_des_maxburstlen[g]),
            .trigcfg_regval_err(c_trigsel_range_err[g]),
            .src_orig(c_src_orig[g]), .des_orig(c_des_orig[g]),
            .srcx_orig(c_srcx_orig[g]), .desx_orig(c_desx_orig[g]),
            .live_we(c_live_we[g]), .live_srcaddr(c_live_srcaddr[g]),
            .live_desaddr(c_live_desaddr[g]), .live_src_xsize(c_live_src_xsize[g]),
            .live_des_xsize(c_live_des_xsize[g]),
            .iwr_en(c_iwr_en[g]), .iwr_off(c_iwr_off[g]),
            .iwr_data(c_iwr_data[g]), .iwr_regclear(c_iwr_regclear[g]),
            .src_trig_pending(c_src_trig_pending[g]), .src_trig_type(c_src_trig_type[g]),
            .src_trig_take(c_src_trig_take[g]),
            .src_trig_take_last(c_src_trig_take_last[g]),
            .des_trig_pending(c_des_trig_pending[g]), .des_trig_type(c_des_trig_type[g]),
            .des_trig_take(c_des_trig_take[g]),
            .des_trig_take_last(c_des_trig_take_last[g]),
            .trigout_start(c_trigout_start[g]), .trigout_done(c_trigout_done[g]),
            .m_axi_araddr(c_araddr[g]), .m_axi_arlen(c_arlen[g]),
            .m_axi_arsize(c_arsize[g]), .m_axi_arburst(c_arburst[g]),
            .m_axi_arvalid(c_arvalid[g]),
            .m_axi_arcmdlink(c_arcmdlink[g]), .m_axi_arready(c_arready[g]),
            .m_axi_rdata(mgr_vec[g] ? c_rdata_m1 : c_rdata_m0),
            .m_axi_rresp(mgr_vec[g] ? c_rresp_m1 : c_rresp_m0),
            .m_axi_rpoison(mgr_vec[g] ? c_rpoison_m1 : c_rpoison_m0),
            .m_axi_rlast(mgr_vec[g] ? c_rlast_m1 : c_rlast_m0),
            .m_axi_rvalid(c_rvalid[g]),
            .m_axi_rready(c_rready[g]),
            .m_axi_awaddr(c_awaddr[g]), .m_axi_awlen(c_awlen[g]),
            .m_axi_awsize(c_awsize[g]), .m_axi_awburst(c_awburst[g]),
            .m_axi_awvalid(c_awvalid[g]),
            .m_axi_awready(c_awready[g]),
            .m_axi_wdata(c_wdata[g]), .m_axi_wstrb(c_wstrb[g]),
            .m_axi_wlast(c_wlast[g]), .m_axi_wvalid(c_wvalid[g]),
            .m_axi_wready(c_wready[g]),
            .m_axi_bresp(mgr_vec[g] ? c_bresp_m1 : c_bresp_m0),
            .m_axi_bvalid(c_bvalid[g]), .m_axi_bready(c_bready[g]),
            .m_axis_out_tdata(str_out_tdata[g*DATA_WIDTH +: DATA_WIDTH]),
            .m_axis_out_tvalid(str_out_tvalid[g]),
            .m_axis_out_tready(str_out_tready[g]),
            .m_axis_out_tlast(str_out_tlast[g]),
            .s_axis_in_tdata(str_in_tdata[g*DATA_WIDTH +: DATA_WIDTH]),
            .s_axis_in_tstrb(str_in_tstrb[g*STRB_W +: STRB_W]),
            .s_axis_in_tvalid(str_in_tvalid[g]),
            .s_axis_in_tready(str_in_tready[g]),
            .s_axis_in_tlast(str_in_tlast[g]),
            .s_axis_in_flush(str_in_flush[g]),
            .srctrigin_sel_err(c_srctrigin_sel_err[g]),
            .destrigin_sel_err(c_destrigin_sel_err[g]),
            .trigout_sel_err(c_trigout_sel_err[g])
        );

        // boot loader: only channel 0 boots from boot_addr
        assign c_boot_req[g] = (g == 0) ? boot_pulse : 1'b0;

        // pack AXI user bundles. AxPROT (TRM 4.3.9 / 6.5.1.11-12):
        //   [0] privileged   = TRANSCFG.PRIVATTR, tied 0 for an unpriv channel
        //   [1] non-secure   = TRANSCFG.NONSECATTR, tied 1 for a NS channel
        //   [2] instruction  = 1 only for command-link reads (data access = 0)
        // The SW channel-ID (NSEC/SEC_CHCFG.CHID) is driven when CHIDVLD is
        // set, otherwise the channel index is used.
        localparam int CHID_G = g;
        wire [2:0] c_arprot_eff = {c_arcmdlink[g],
                                   c_src_prot[g][1] | c_nonsec[g],
                                   c_src_prot[g][0] & c_priv[g]};
        wire [2:0] c_awprot_eff = {1'b0,
                                   c_des_prot[g][1] | c_nonsec[g],
                                   c_des_prot[g][0] & c_priv[g]};
        wire [CHIDNZ-1:0] c_chid_eff = ((CHID_WIDTH > 0) && chidvld_q[g])
                                       ? chid_q[g][CHIDNZ-1:0]
                                       : CHID_G[CHIDNZ-1:0];
        assign c_aruser[g] = pack_aruser(c_arprot_eff, c_src_cache[g],
                                         c_src_domain[g], c_src_inner[g],
                                         c_chprio[g], c_chid_eff,
                                         c_arcmdlink[g]);
        assign c_awuser[g] = pack_awuser(c_awprot_eff, c_des_cache[g],
                                         c_des_domain[g], c_des_inner[g],
                                         c_chprio[g], c_chid_eff);

        // stream sideband: full byte strobes, flush hint while flow-controlled
        assign str_out_tstrb[g*STRB_W +: STRB_W] = {STRB_W{1'b1}};

        // GPO: registered output holding its last driven value (TRM 4.8.1)
        assign gpo_ch[g*GPO_WIDTH +: GPO_WIDTH] = c_gpo_out[g];

        // per-channel status outputs
        assign ch_enabled[g] = c_ch_enabled[g];
        assign ch_paused[g]  = c_paused[g];
        assign ch_priv[g]    = c_priv[g];
        assign ch_nonsec[g]  = c_nonsec[g];
    end endgenerate

    // =====================================================================
    // Sticky ch_err / ch_stopped (status indication, level)
    // =====================================================================
    reg [NC-1:0] err_lvl, stop_lvl;
    always_ff @(posedge clk)
        if (!resetn) begin err_lvl <= '0; stop_lvl <= '0; end
        else begin
            for (int i = 0; i < NC; i++) begin
                if (c_error_p[i])    err_lvl[i]  <= 1'b1;
                if (c_stopped_p[i])  stop_lvl[i] <= 1'b1;
                if (c_enablecmd[i])  begin err_lvl[i] <= 1'b0; stop_lvl[i] <= 1'b0; end
            end
        end
    assign ch_err     = err_lvl;
    assign ch_stopped = stop_lvl;

    // =====================================================================
    // APB read data / error mux across channels + DMA-level block
    // =====================================================================
    reg   [31:0] prdata_r;
    always_ff @(posedge clk) begin
        if (!resetn) prdata_r <= 32'h0;
        else if (psel & ~penable) begin
            if (apb_blocked)                      prdata_r <= 32'h0;   // RAZ
            else if (apb_is_chan && apb_chan_idx < NC) prdata_r <= ch_prdata[apb_chan_idx];
            else                                  prdata_r <= dma_lvl_rdata;
        end
    end
    assign prdata  = prdata_r;
    // Security violations answer with SLVERR when SCFG_CTRL.RSPTYPE_SECACCVIO
    // is set (RAZ/WI otherwise); debugger accesses (pdebug) never error.
    assign pslverr = (apb_sec_viol & scfg_rsptype_q & ~pdebug) ? 1'b1
                   : apb_blocked ? 1'b0
                   : apb_is_chan ? ((apb_chan_idx < NC) ? ch_pslverr[apb_chan_idx]
                                                        : 1'b1)   // unmapped channel
                                 : 1'b0;

    // =====================================================================
    // DMA-unit register ID / build-config constants (read in the DMAINFO and
    // per-channel ID registers). Frame decode + register storage follow below.
    // =====================================================================
    localparam [31:0] DMA_IIDR_VAL = 32'h3A00_043B;   // PRODUCTID=0x3A0, IMPL=0x43B (Arm)
    localparam [31:0] DMA_AIDR_VAL = 32'h0000_0010;   // architecture 1.0
    // BUILDCFG0: [4:0]=NUM_CHANNELS, [13:8]=ADDR_WIDTH, [23:16]=DATA_WIDTH
    localparam [31:0] DMA_BUILDCFG0_VAL =
        { 8'd0, DATA_WIDTH[7:0], 2'd0, ADDR_WIDTH[5:0], 3'd0, NC[4:0] };
    localparam [31:0] DMA_BUILDCFG1_VAL = {28'd0, NUM_TRIGGER_IN[3:0]};
    localparam [31:0] DMA_BUILDCFG2_VAL = {28'd0, NUM_TRIGGER_OUT[3:0]};
    // Peripheral ID (TRM 6.5.5): DMA-350 part 0x3A0, Arm JEP106 (0x4,0x3B).
    // PIDR4.SIZE = number of 4KB pages used = ceil(NUM_CHANNELS/16).
    localparam int    PIDR_PG       = (NC + 15) / 16;
    localparam [31:0] DMA_PIDR4_VAL = {24'b0, PIDR_PG[3:0], 4'h4};  // SIZE, DES_2=0x4
    localparam [31:0] DMA_PIDR0_VAL = 32'h0000_00A0;  // PART_0 = 0xA0
    localparam [31:0] DMA_PIDR1_VAL = 32'h0000_00B3;  // DES_0=0xB, PART_1=0x3
    localparam [31:0] DMA_PIDR2_VAL = 32'h0000_000B;  // REV=0, JEDEC=1, DES_1=0x3
    localparam [31:0] DMA_PIDR3_VAL = 32'h0000_0000;  // REVAND=0, CMOD=0

    wire [31:0] nsec_chintr = {{(32-NC){1'b0}}, (c_irq &  c_nonsec)};
    wire [31:0] sec_chintr  = (SECEXT_PRESENT!=0) ? {{(32-NC){1'b0}}, (c_irq & ~c_nonsec)} : 32'h0;

    // =====================================================================
    // DMA-unit register frames (TRM 6.4.2-6.4.5). Frame bases per the TRM 6.3
    // memory map, decoded by paddr[11:8]:
    //   0x0 DMASECCFG  0x1 DMASECCTRL  0x2 DMANSECCTRL  0xF DMAINFO
    // (DMASECCFG is at 0x0000, DMAINFO at 0x0F00.)
    // =====================================================================
    // channel busy/idle/stopped/paused views (used here for the *_STATUS /
    // *_STATUSVAL read-back and below for all-channel ack + CTI halt).
    wire [NC-1:0] is_idle    = ~c_busy;
    wire [NC-1:0] is_stopped = stop_lvl | is_idle;
    wire [NC-1:0] is_paused  = c_paused | is_idle;

    // ---- DMASECCFG storage (TRM 6.5.4): per-channel security (SCFG_CHSEC0)
    //      / privilege (SCFG_CHPRIV0), trigger-port security mapping
    //      (SCFG_TRIGIN/OUTSEC0), security control (SCFG_CTRL) and the
    //      violation status (SCFG_INTRSTATUS). Channel 0 boots Secure. ----
    localparam [15:0] CHID_RMASK = (CHID_WIDTH <= 0)  ? 16'h0000 :
                                   (CHID_WIDTH >= 16) ? 16'hFFFF :
                                   ((16'h1 << CHID_WIDTH) - 16'h1);

    reg  [NC-1:0]              scfg_chsec_q;   // 1 = channel is Secure
    reg  [NC-1:0]              scfg_chpriv_q;  // 1 = channel is Privileged
    reg                        scfg_lock_q;    // SCFG_CTRL.SEC_CFG_LCK [31]
    reg                        scfg_intren_q;  // SCFG_CTRL.INTREN_SECACCVIO [0]
    // (scfg_rsptype_q is forward-declared above, before the pslverr mux)
    reg  [NUM_TRIGGER_IN-1:0]  scfg_triginsec_q;   // 1 = Non-secure trigger-in
    reg  [NUM_TRIGGER_OUT-1:0] scfg_trigoutsec_q;  // 1 = Non-secure trigger-out
    reg                        stat_secaccvio_q;   // SCFG_INTRSTATUS.STAT [16]

    // Secure / Non-secure control-frame pointers + control registers
    // (chid_q / chidvld_q are declared with the forward declarations above)
    reg  [5:0]  sec_chptr_q,     nsec_chptr_q;
    reg  [3:0]  sec_statusptr_q, nsec_statusptr_q;
    reg  [3:0]  sec_signalptr_q, nsec_signalptr_q;
    reg  [31:0] sec_ctrl_q,      nsec_ctrl_q;

    // security violation: any blocked Non-secure access (Secure channel frame
    // or Secure unit frame); suppressed for debugger accesses (TRM 4.2.3).
    wire sec_viol_set = (SECEXT_PRESENT != 0) & psel & penable
                      & apb_sec_viol & ~pdebug;

    // trigger-in port ownership: port currently selected by an enabled channel
    // (used to qualify the SW deny function of *_SIGNALVAL, TRM 6.5.2.9)
    always_comb begin
        ti_selected = '0;
        for (int c = 0; c < NC; c++) begin
            if (c_ch_enabled[c] && c_srctrigin_en[c] && c_srctrigin_hw[c]
                && (c_srctrigin_sel[c] < NUM_TRIGGER_IN))
                ti_selected[c_srctrigin_sel[c]] = 1'b1;
            if (c_ch_enabled[c] && c_destrigin_en[c] && c_destrigin_hw[c]
                && (c_destrigin_sel[c] < NUM_TRIGGER_IN))
                ti_selected[c_destrigin_sel[c]] = 1'b1;
        end
    end

    wire        dma_unit_wr = psel & penable & pwrite & ~apb_is_chan & ~apb_blocked;
    wire [3:0]  uframe      = paddr[11:8];
    wire [7:0]  uoff        = paddr[7:0];

    always_ff @(posedge clk) begin
        if (!resetn) begin
            scfg_chsec_q  <= {{(NC-1){1'b0}}, (SECEXT_PRESENT!=0)};  // ch0 Secure
            scfg_chpriv_q <= {NC{1'b1}};                            // all Privileged
            scfg_lock_q   <= 1'b0;
            scfg_intren_q <= 1'b0;
            scfg_rsptype_q<= 1'b0;
            scfg_triginsec_q  <= '0;
            scfg_trigoutsec_q <= '0;
            stat_secaccvio_q  <= 1'b0;
            chidvld_q <= '0;
            for (int i = 0; i < NC; i++) chid_q[i] <= 16'h0;
            sec_chptr_q<=0;     nsec_chptr_q<=0;
            sec_statusptr_q<=0; nsec_statusptr_q<=0;
            sec_signalptr_q<=0; nsec_signalptr_q<=0;
            sec_ctrl_q<=0;      nsec_ctrl_q<=0;
            ti_deny <= '0;
        end else begin
            ti_deny <= '0;                                // 1-cycle deny pulses
            if (sec_viol_set) stat_secaccvio_q <= 1'b1;   // sticky violation

            if (dma_unit_wr) begin
                case (uframe)
                // ---- 0x0 DMASECCFG (frozen by SEC_CFG_LCK; Secure config) ----
                4'h0: begin
                    if ((SECEXT_PRESENT!=0) && !scfg_lock_q) begin
                        case (uoff)
                            8'h00: scfg_chsec_q      <= pwdata[NC-1:0];               // SCFG_CHSEC0
                            8'h08: scfg_triginsec_q  <= pwdata[NUM_TRIGGER_IN-1:0];   // SCFG_TRIGINSEC0
                            8'h10: scfg_chpriv_q     <= pwdata[NC-1:0];               // SCFG_CHPRIV0
                            8'h28: scfg_trigoutsec_q <= pwdata[NUM_TRIGGER_OUT-1:0];  // SCFG_TRIGOUTSEC0
                            8'h40: begin                                             // SCFG_CTRL
                                scfg_intren_q  <= pwdata[0];
                                scfg_rsptype_q <= pwdata[1];
                                if (pwdata[31]) scfg_lock_q <= 1'b1;                 // W1S lock
                            end
                            default: ;
                        endcase
                    end
                    // STAT_SECACCVIO (W1C) clearable even when the config is locked
                    if ((SECEXT_PRESENT!=0) && uoff==8'h44 && pwdata[16])
                        stat_secaccvio_q <= 1'b0;                                    // SCFG_INTRSTATUS
                end
                // ---- 0x1 DMASECCTRL (Secure channels) ----
                4'h1: case (uoff)
                    8'h0C: sec_ctrl_q      <= pwdata;          // SEC_CTRL
                    8'h14: sec_chptr_q     <= pwdata[5:0];     // SEC_CHPTR
                    8'h18: if (sec_chptr_q < NC) begin         // SEC_CHCFG
                               scfg_chpriv_q[sec_chptr_q] <= pwdata[17];
                               chidvld_q[sec_chptr_q]     <= pwdata[16];
                               chid_q[sec_chptr_q]        <= pwdata[15:0];
                           end
                    8'hF0: sec_statusptr_q <= pwdata[3:0];     // SEC_STATUSPTR
                    8'hF8: sec_signalptr_q <= pwdata[3:0];     // SEC_SIGNALPTR
                    8'hFC: if (sec_signalptr_q == 4'd0) begin  // SEC_SIGNALVAL W1C
                               // deny a pending request on a Secure trigger-in
                               // port not selected by any channel (TRM 6.5.3.9)
                               for (int t = 0; t < NUM_TRIGGER_IN; t++)
                                   if (pwdata[t] && !ti_selected[t]
                                       && !scfg_triginsec_q[t])
                                       ti_deny[t] <= 1'b1;
                           end
                    default: ;
                endcase
                // ---- 0x2 DMANSECCTRL (Non-secure channels) ----
                4'h2: case (uoff)
                    8'h0C: nsec_ctrl_q      <= pwdata;         // NSEC_CTRL
                    8'h14: nsec_chptr_q     <= pwdata[5:0];    // NSEC_CHPTR
                    8'h18: if (nsec_chptr_q < NC) begin        // NSEC_CHCFG
                               scfg_chpriv_q[nsec_chptr_q] <= pwdata[17];
                               chidvld_q[nsec_chptr_q]     <= pwdata[16];
                               chid_q[nsec_chptr_q]        <= pwdata[15:0];
                           end
                    8'hF0: nsec_statusptr_q <= pwdata[3:0];    // NSEC_STATUSPTR
                    8'hF8: nsec_signalptr_q <= pwdata[3:0];    // NSEC_SIGNALPTR
                    8'hFC: if (nsec_signalptr_q == 4'd0) begin // NSEC_SIGNALVAL W1C
                               // deny a pending request on a Non-secure
                               // trigger-in port not selected by any channel
                               for (int t = 0; t < NUM_TRIGGER_IN; t++)
                                   if (pwdata[t] && !ti_selected[t]
                                       && scfg_triginsec_q[t])
                                       ti_deny[t] <= 1'b1;
                           end
                    default: ;
                endcase
                default: ;
                endcase
            end
        end
    end

    // per-channel security/privilege context drives the AXI protection bits
    assign c_nonsec = (SECEXT_PRESENT!=0) ? ~scfg_chsec_q : {NC{1'b1}};
    assign c_priv   = scfg_chpriv_q;
    wire [31:0] scfg_chsec = {{(32-NC){1'b0}}, scfg_chsec_q};

    wire [NC-1:0] nsec_mask = c_nonsec;
    wire [NC-1:0] sec_mask  = ~c_nonsec;

    // NSEC/SEC_STATUS: all-channel idle/stopped/paused (level) + combined intr.
    function automatic [31:0] unit_status(input [NC-1:0] mask, input [NC-1:0] irqs);
        unit_status      = 32'h0;
        unit_status[19]  = &(~mask | is_paused);    // STAT_ALLCHPAUSED
        unit_status[18]  = &(~mask | is_stopped);   // STAT_ALLCHSTOPPED
        unit_status[17]  = &(~mask | is_idle);      // STAT_ALLCHIDLE
        unit_status[0]   = |(irqs & mask);          // INTR_ANYCHINTR
    endfunction

    // NSEC/SEC_CHCFG: privilege/CHID of the channel selected by *_CHPTR.
    function automatic [31:0] unit_chcfg(input [5:0] ptr);
        unit_chcfg = 32'h0;
        if (ptr < NC) begin
            unit_chcfg[17]   = scfg_chpriv_q[ptr];
            unit_chcfg[16]   = (CHID_WIDTH > 0) ? chidvld_q[ptr] : 1'b0;
            unit_chcfg[15:0] = chid_q[ptr] & CHID_RMASK;
        end
    endfunction

    // NSEC/SEC_STATUSVAL: channel enable/stop/pause vectors (masked, RO).
    function automatic [31:0] unit_statusval(input [3:0] ptr, input [NC-1:0] mask);
        logic [NC-1:0] v;
        case (ptr)
            4'd0:    v = ch_enabled & mask;   // enabled status
            4'd2:    v = stop_lvl   & mask;   // stopped status
            4'd4:    v = c_paused   & mask;   // paused status
            default: v = '0;
        endcase
        unit_statusval = {{(32-NC){1'b0}}, v};
    endfunction

    // NSEC/SEC_SIGNALVAL: trigger-in / trigger-out signal view, masked by the
    // trigger-port security mapping (GPO view needs HAS_GPOSEL, absent here).
    function automatic [31:0] unit_signalval(input [3:0] ptr, input nsv);
        unit_signalval = 32'h0;
        case (ptr)
            4'd0: for (int t = 0; t < NUM_TRIGGER_IN; t++)
                      if (ti_pending[t] & (scfg_triginsec_q[t] == nsv))
                          unit_signalval[t] = 1'b1;
            4'd8: for (int t = 0; t < NUM_TRIGGER_OUT; t++)
                      if (trig_out_req[t] & (scfg_trigoutsec_q[t] == nsv))
                          unit_signalval[t] = 1'b1;
            default: ;
        endcase
    endfunction

    function automatic [31:0] dma_unit_rd(input [3:0] frame, input [7:0] off);
        dma_unit_rd = 32'h0;
        case (frame)
            4'h0: case (off)                            // DMASECCFG
                8'h00: dma_unit_rd = scfg_chsec;                                       // SCFG_CHSEC0 (1=Secure)
                8'h08: dma_unit_rd = {{(32-NUM_TRIGGER_IN){1'b0}},  scfg_triginsec_q};  // SCFG_TRIGINSEC0
                8'h10: dma_unit_rd = {{(32-NC){1'b0}}, scfg_chpriv_q};                  // SCFG_CHPRIV0
                8'h28: dma_unit_rd = {{(32-NUM_TRIGGER_OUT){1'b0}}, scfg_trigoutsec_q}; // SCFG_TRIGOUTSEC0
                8'h40: dma_unit_rd = {scfg_lock_q, 29'b0, scfg_rsptype_q, scfg_intren_q}; // SCFG_CTRL
                8'h44: dma_unit_rd = {15'b0, stat_secaccvio_q, 15'b0,
                                      (stat_secaccvio_q & scfg_intren_q)};             // SCFG_INTRSTATUS
                default: ;
            endcase
            4'h1: case (off)                            // DMASECCTRL
                8'h00: dma_unit_rd = sec_chintr;                                  // SEC_CHINTRSTATUS0
                8'h08: dma_unit_rd = unit_status(sec_mask, c_irq & ~c_nonsec);    // SEC_STATUS
                8'h0C: dma_unit_rd = sec_ctrl_q;                                  // SEC_CTRL
                8'h14: dma_unit_rd = {26'b0, sec_chptr_q};                        // SEC_CHPTR
                8'h18: dma_unit_rd = unit_chcfg(sec_chptr_q);                     // SEC_CHCFG
                8'hF0: dma_unit_rd = {28'b0, sec_statusptr_q};                    // SEC_STATUSPTR
                8'hF4: dma_unit_rd = unit_statusval(sec_statusptr_q, sec_mask);   // SEC_STATUSVAL
                8'hF8: dma_unit_rd = {28'b0, sec_signalptr_q};                    // SEC_SIGNALPTR
                8'hFC: dma_unit_rd = unit_signalval(sec_signalptr_q, 1'b0);       // SEC_SIGNALVAL
                default: ;
            endcase
            4'h2: case (off)                            // DMANSECCTRL
                8'h00: dma_unit_rd = nsec_chintr;                                 // NSEC_CHINTRSTATUS0
                8'h08: dma_unit_rd = unit_status(nsec_mask, c_irq & c_nonsec);    // NSEC_STATUS
                8'h0C: dma_unit_rd = nsec_ctrl_q;                                 // NSEC_CTRL
                8'h14: dma_unit_rd = {26'b0, nsec_chptr_q};                       // NSEC_CHPTR
                8'h18: dma_unit_rd = unit_chcfg(nsec_chptr_q);                    // NSEC_CHCFG
                8'hF0: dma_unit_rd = {28'b0, nsec_statusptr_q};                   // NSEC_STATUSPTR
                8'hF4: dma_unit_rd = unit_statusval(nsec_statusptr_q, nsec_mask); // NSEC_STATUSVAL
                8'hF8: dma_unit_rd = {28'b0, nsec_signalptr_q};                   // NSEC_SIGNALPTR
                8'hFC: dma_unit_rd = unit_signalval(nsec_signalptr_q, 1'b1);      // NSEC_SIGNALVAL
                default: ;
            endcase
            4'hF: case (off)                            // DMAINFO (0x0F00)
                8'hB0: dma_unit_rd = DMA_BUILDCFG0_VAL;
                8'hB4: dma_unit_rd = DMA_BUILDCFG1_VAL;
                8'hB8: dma_unit_rd = DMA_BUILDCFG2_VAL;
                8'hC8: dma_unit_rd = DMA_IIDR_VAL;
                8'hCC: dma_unit_rd = DMA_AIDR_VAL;
                8'hD0: dma_unit_rd = DMA_PIDR4_VAL;   // PIDR4
                8'hE0: dma_unit_rd = DMA_PIDR0_VAL;   // PIDR0
                8'hE4: dma_unit_rd = DMA_PIDR1_VAL;   // PIDR1
                8'hE8: dma_unit_rd = DMA_PIDR2_VAL;   // PIDR2
                8'hEC: dma_unit_rd = DMA_PIDR3_VAL;   // PIDR3
                8'hF0: dma_unit_rd = 32'h0000_000D;   // CIDR0
                8'hF4: dma_unit_rd = 32'h0000_00F0;   // CIDR1
                8'hF8: dma_unit_rd = 32'h0000_0005;   // CIDR2
                8'hFC: dma_unit_rd = 32'h0000_00B1;   // CIDR3
                default: ;
            endcase
            default: ;
        endcase
    endfunction

    assign dma_lvl_rdata = dma_unit_rd(paddr[11:8], paddr[7:0]);

    // Security-violation interrupt (TRM 6.5.4): sticky status gated by INTREN.
    assign irq_sec_viol_err = (SECEXT_PRESENT != 0)
                            ? (stat_secaccvio_q & scfg_intren_q) : 1'b0;

    // =====================================================================
    // IRQ aggregation. The combined interrupts include the channel interrupts
    // only when INTREN_ANYCHINTR (NSEC/SEC_CTRL[0]) is set (TRM 5.11).
    // =====================================================================
    assign irq_channel    = c_irq;
    assign irq_comb_nonsec = |(c_irq & c_nonsec) & nsec_ctrl_q[0];
    assign irq_comb_sec    = (SECEXT_PRESENT != 0)
                           ? (|(c_irq & ~c_nonsec) & sec_ctrl_q[0]) : 1'b0;

    // =====================================================================
    // All-channel stop/pause acknowledge (4-phase): asserted when every
    // targeted channel is stopped/idle (stop) or paused/idle (pause).
    // =====================================================================
    assign allch_stop_ack_nonsec  = &(~c_nonsec | is_stopped);   // all nonsec stopped
    assign allch_pause_ack_nonsec = &(~c_nonsec | is_paused);
    assign allch_stop_ack_sec  = (SECEXT_PRESENT!=0) ? &( c_nonsec | is_stopped) : 1'b1;
    assign allch_pause_ack_sec = (SECEXT_PRESENT!=0) ? &( c_nonsec | is_paused)  : 1'b1;

    // =====================================================================
    // CTI halt: 'halted' pulses once every channel is paused or idle while
    // halt_req is held (Appendix A: pulse indication, Cross Trigger Interface).
    // =====================================================================
    reg halted_r, halted_lvl;
    wire all_halted = &(is_idle | c_paused);
    always_ff @(posedge clk)
        if (!resetn) begin halted_r <= 1'b0; halted_lvl <= 1'b0; end
        else begin
            halted_r   <= halt_req & all_halted & ~halted_lvl;  // 1-cycle pulse
            halted_lvl <= halt_req & all_halted;
        end
    assign halted = halted_r;

    // =====================================================================
    // Boot loader: one-shot enable pulse to channel 0 after reset
    // =====================================================================
    reg boot_done;
    // (boot_pulse is forward-declared with the channel-generate nets above)
    always_ff @(posedge clk)
        if (!resetn) begin boot_done <= 1'b0; boot_pulse <= 1'b0; end
        else begin
            boot_pulse <= 1'b0;
            if (boot_en && !boot_done && !c_busy[0]) begin
                boot_pulse <= 1'b1;
                boot_done  <= 1'b1;
            end
        end

    // =====================================================================
    // Trigger matrix
    // =====================================================================
    generate
        // input ports
        for (g = 0; g < NUM_TRIGGER_IN; g = g + 1) begin : g_ti
            dma350_trig_in u_ti (
                .clk(clk), .resetn(resetn),
                .trig_in_req(trig_in_req[g]),
                .trig_in_req_type(trig_in_req_type[g*2 +: 2]),
                .trig_in_ack(trig_in_ack[g]),
                .trig_in_ack_type(trig_in_ack_type[g*2 +: 2]),
                .pending(ti_pending[g]), .pending_type(ti_type[g]),
                .take(ti_take[g]), .take_last(ti_take_last[g]),
                .deny(ti_deny[g])
            );
        end
        // output ports
        for (g = 0; g < NUM_TRIGGER_OUT; g = g + 1) begin : g_to
            dma350_trig_out u_to (
                .clk(clk), .resetn(resetn),
                .trig_out_req(trig_out_req[g]), .trig_out_ack(trig_out_ack[g]),
                .start(to_start[g]), .busy(), .done(to_done[g])
            );
        end
    endgenerate

    // route triggers to/from channels. Each trigger-in / trigger-out is one of:
    // SW-only (TYPE=00, no port), an EXTERNAL HW port (TYPE=10, select < ports)
    // or an INTERNAL channel-to-channel connection (TYPE=11, select = channel).
    generate for (g = 0; g < NC; g = g + 1) begin : g_trmux
        // internal source-trigger pending = the source channel's internal req
        wire int_src_ok = c_srctrigin_internal[g] & (c_srctrigin_sel[g] < NC);
        wire int_des_ok = c_destrigin_internal[g] & (c_destrigin_sel[g] < NC);
        wire int_src_pend = int_src_ok & int_req[c_srctrigin_sel[g][3:0]];
        wire int_des_pend = int_des_ok & int_req[c_destrigin_sel[g][3:0]];
        wire src_hw_ok = c_srctrigin_hw[g] & (c_srctrigin_sel[g] < NUM_TRIGGER_IN);
        wire des_hw_ok = c_destrigin_hw[g] & (c_destrigin_sel[g] < NUM_TRIGGER_IN);

        assign c_src_trig_pending[g] = c_srctrigin_en[g] &
            (c_srctrigin_internal[g] ? int_src_pend
             : (src_hw_ok ? ti_pending[c_srctrigin_sel[g]] : 1'b0));
        assign c_src_trig_type[g]    = c_srctrigin_internal[g] ? TRIGREQ_SINGLE :
            (src_hw_ok ? ti_type[c_srctrigin_sel[g]] : TRIGREQ_SINGLE);
        assign c_des_trig_pending[g] = c_destrigin_en[g] &
            (c_destrigin_internal[g] ? int_des_pend
             : (des_hw_ok ? ti_pending[c_destrigin_sel[g]] : 1'b0));
        assign c_des_trig_type[g]    = c_destrigin_internal[g] ? TRIGREQ_SINGLE :
            (des_hw_ok ? ti_type[c_destrigin_sel[g]] : TRIGREQ_SINGLE);
        // trigger-out done: internal -> when the target channel accepted it;
        // external HW -> from the trigger-out handshake port; SW-only -> never
        // from the matrix (completed by CH_CMD.SWTRIGOUTACK inside the channel).
        assign c_trigout_done[g] = c_trigout_internal[g] ? int_ack[g] :
            c_trigout_hw[g] ? ((c_trigout_sel[g] < NUM_TRIGGER_OUT)
                               ? to_done[c_trigout_sel[g]] : 1'b1)
                            : 1'b0;
    end endgenerate

    // internal trigger handshake: sender s raises int_req on its (internal)
    // trigger-out start and holds it until a receiving channel takes it.
    generate for (g = 0; g < NC; g = g + 1) begin : g_intack
        wire [NC-1:0] took;
        for (genvar c = 0; c < NC; c = c + 1) begin : g_c
            // receiver c whose internal source is sender g and which took it
            assign took[c] = (c_src_trig_take[c] & c_srctrigin_internal[c]
                                & (c_srctrigin_sel[c][3:0] == g[3:0]))
                           | (c_des_trig_take[c] & c_destrigin_internal[c]
                                & (c_destrigin_sel[c][3:0] == g[3:0]));
        end
        assign int_ack[g] = |took;
    end endgenerate
    always_ff @(posedge clk) begin
        if (!resetn) int_req <= '0;
        else for (int s = 0; s < NC; s++) begin
            if (c_trigout_internal[s] & c_trigout_start[s]) int_req[s] <= 1'b1;
            else if (int_ack[s])                            int_req[s] <= 1'b0;
        end
    end

    // trigger-port selection errors (TRM 5.4.3 / 6.5.1.33):
    //  * conflict: an external HW trigger-in/out port selected by more than one
    //    enabled channel -> EI_*TRIGINSELERR / EI_TRIGOUTSELERR;
    //  * range: a HW selector beyond the implemented ports, or an internal
    //    selector pointing past the channels or at itself -> REGVALERR.
    generate for (g = 0; g < NC; g = g + 1) begin : g_trsel
        wire [NC-1:0] sh, dh, oh;
        for (genvar c = 0; c < NC; c = c + 1) begin : g_c
            assign sh[c] = (c != g) & c_srctrigin_en[c] & c_srctrigin_hw[c]
                                    & (c_srctrigin_sel[c] == c_srctrigin_sel[g]);
            assign dh[c] = (c != g) & c_destrigin_en[c] & c_destrigin_hw[c]
                                    & (c_destrigin_sel[c] == c_destrigin_sel[g]);
            assign oh[c] = (c != g) & c_trigout_en[c] & c_trigout_hw[c]
                                    & (c_trigout_sel[c] == c_trigout_sel[g]);
        end
        assign c_srctrigin_sel_err[g] = c_srctrigin_en[g] & c_srctrigin_hw[g] & (|sh);
        assign c_destrigin_sel_err[g] = c_destrigin_en[g] & c_destrigin_hw[g] & (|dh);
        assign c_trigout_sel_err[g]   = c_trigout_en[g]   & c_trigout_hw[g]   & (|oh);
        assign c_trigsel_range_err[g] =
              (c_srctrigin_en[g] & c_srctrigin_hw[g]
                                 & (c_srctrigin_sel[g] >= NUM_TRIGGER_IN))
            | (c_destrigin_en[g] & c_destrigin_hw[g]
                                 & (c_destrigin_sel[g] >= NUM_TRIGGER_IN))
            | (c_trigout_en[g]   & c_trigout_hw[g]
                                 & (c_trigout_sel[g]   >= NUM_TRIGGER_OUT))
            | (c_srctrigin_en[g] & c_srctrigin_internal[g]
                                 & ((c_srctrigin_sel[g] >= NC) | (c_srctrigin_sel[g] == g)))
            | (c_destrigin_en[g] & c_destrigin_internal[g]
                                 & ((c_destrigin_sel[g] >= NC) | (c_destrigin_sel[g] == g)));
    end endgenerate

    // OR-combine EXTERNAL take (with its LAST OKAY qualifier) into each input
    // port, start into each output port (internal and SW-only are excluded).
    generate for (g = 0; g < NUM_TRIGGER_IN; g = g + 1) begin : g_ti_take
        wire [NC-1:0] hit_src, hit_des, hit_src_l, hit_des_l;
        for (genvar c = 0; c < NC; c = c + 1) begin : g_c
            assign hit_src[c]   = c_src_trig_take[c] & c_srctrigin_hw[c]
                                                     & (c_srctrigin_sel[c] == g);
            assign hit_des[c]   = c_des_trig_take[c] & c_destrigin_hw[c]
                                                     & (c_destrigin_sel[c] == g);
            assign hit_src_l[c] = hit_src[c] & c_src_trig_take_last[c];
            assign hit_des_l[c] = hit_des[c] & c_des_trig_take_last[c];
        end
        assign ti_take[g]      = |hit_src   | |hit_des;
        assign ti_take_last[g] = |hit_src_l | |hit_des_l;
    end endgenerate
    generate for (g = 0; g < NUM_TRIGGER_OUT; g = g + 1) begin : g_to_start
        wire [NC-1:0] hit;
        for (genvar c = 0; c < NC; c = c + 1) begin : g_c
            assign hit[c] = c_trigout_start[c] & c_trigout_hw[c]
                                               & (c_trigout_sel[c] == g);
        end
        assign to_start[g] = |hit;
    end endgenerate

    // =====================================================================
    // AXI5 manager arbitration node(s)
    // =====================================================================
    // physical node M0 / M1 connection wires
    wire [ARUSER_W-1:0] m0_aruser, m1_aruser;
    wire [AWUSER_W-1:0] m0_awuser, m1_awuser;
    wire [1:0]          m0_arburst, m0_awburst, m1_arburst, m1_awburst;
    wire                poison_m0 = |rpoison_m0;
    wire                poison_m1 = |rpoison_m1;

    generate if (AXI5_M1_PRESENT != 0) begin : g_two_ports
        // Two full managers. Each channel is assigned (via mgr_vec) to exactly
        // one manager for BOTH its reads and writes; a manager arbitrates only
        // the channels routed to it (AR/AW valids masked). This matches the
        // DMA-350 model — a whole channel maps to a manager, reads and writes
        // are NOT split across ports.
        dma350_axi_node #(.N(NC), .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
                          .ID_WIDTH(ID_WIDTH), .ARUSER_W(ARUSER_W), .AWUSER_W(AWUSER_W),
                          .ISSUING_CAP(ISSUING_CAP))
        u_node0 (
            .clk(clk), .resetn(resetn), .ch_prio(c_chprio),
            .ch_arvalid(c_arvalid & ~mgr_vec), .ch_arready(arready0), .ch_araddr(c_araddr),
            .ch_arlen(c_arlen), .ch_arsize(c_arsize), .ch_arburst(c_arburst),
            .ch_aruser(c_aruser),
            .ch_rvalid(rvalid0), .ch_rready(c_rready),
            .ch_rdata(c_rdata_m0), .ch_rresp(c_rresp_m0), .ch_rpoison(c_rpoison_m0),
            .ch_rlast(c_rlast_m0),
            .ch_awvalid(c_awvalid & ~mgr_vec), .ch_awready(awready0), .ch_awaddr(c_awaddr),
            .ch_awlen(c_awlen), .ch_awsize(c_awsize), .ch_awburst(c_awburst),
            .ch_awuser(c_awuser),
            .ch_wvalid(c_wvalid), .ch_wready(wready0), .ch_wdata(c_wdata), .ch_wstrb(c_wstrb),
            .ch_wlast(c_wlast), .ch_bvalid(bvalid0), .ch_bready(c_bready), .ch_bresp(c_bresp_m0),
            .m_araddr(araddr_m0), .m_arlen(arlen_m0), .m_arsize(arsize_m0),
            .m_arburst(m0_arburst),
            .m_arid(arid_m0), .m_aruser(m0_aruser), .m_arvalid(arvalid_m0),
            .m_arready(arready_m0), .m_rdata(rdata_m0), .m_rresp(rresp_m0),
            .m_rpoison(poison_m0), .m_rid(rid_m0),
            .m_rlast(rlast_m0), .m_rvalid(rvalid_m0), .m_rready(rready_m0),
            .m_awaddr(awaddr_m0), .m_awlen(awlen_m0), .m_awsize(awsize_m0),
            .m_awburst(m0_awburst),
            .m_awid(awid_m0), .m_awuser(m0_awuser), .m_awvalid(awvalid_m0),
            .m_awready(awready_m0), .m_wdata(wdata_m0), .m_wstrb(wstrb_m0),
            .m_wlast(wlast_m0), .m_wvalid(wvalid_m0), .m_wready(wready_m0),
            .m_bresp(bresp_m0), .m_bvalid(bvalid_m0), .m_bready(bready_m0), .m_bid(bid_m0)
        );
        dma350_axi_node #(.N(NC), .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
                          .ID_WIDTH(ID_WIDTH), .ARUSER_W(ARUSER_W), .AWUSER_W(AWUSER_W),
                          .ISSUING_CAP(ISSUING_CAP))
        u_node1 (
            .clk(clk), .resetn(resetn), .ch_prio(c_chprio),
            .ch_arvalid(c_arvalid & mgr_vec), .ch_arready(arready1), .ch_araddr(c_araddr),
            .ch_arlen(c_arlen), .ch_arsize(c_arsize), .ch_arburst(c_arburst),
            .ch_aruser(c_aruser),
            .ch_rvalid(rvalid1), .ch_rready(c_rready),
            .ch_rdata(c_rdata_m1), .ch_rresp(c_rresp_m1), .ch_rpoison(c_rpoison_m1),
            .ch_rlast(c_rlast_m1),
            .ch_awvalid(c_awvalid & mgr_vec), .ch_awready(awready1), .ch_awaddr(c_awaddr),
            .ch_awlen(c_awlen), .ch_awsize(c_awsize), .ch_awburst(c_awburst),
            .ch_awuser(c_awuser),
            .ch_wvalid(c_wvalid), .ch_wready(wready1), .ch_wdata(c_wdata),
            .ch_wstrb(c_wstrb), .ch_wlast(c_wlast),
            .ch_bvalid(bvalid1), .ch_bready(c_bready), .ch_bresp(c_bresp_m1),
            .m_araddr(araddr_m1), .m_arlen(arlen_m1), .m_arsize(arsize_m1),
            .m_arburst(m1_arburst),
            .m_arid(arid_m1), .m_aruser(m1_aruser), .m_arvalid(arvalid_m1),
            .m_arready(arready_m1), .m_rdata(rdata_m1), .m_rresp(rresp_m1),
            .m_rpoison(poison_m1), .m_rid(rid_m1),
            .m_rlast(rlast_m1), .m_rvalid(rvalid_m1), .m_rready(rready_m1),
            .m_awaddr(awaddr_m1), .m_awlen(awlen_m1), .m_awsize(awsize_m1),
            .m_awburst(m1_awburst),
            .m_awid(awid_m1), .m_awuser(m1_awuser), .m_awvalid(awvalid_m1),
            .m_awready(awready_m1), .m_wdata(wdata_m1), .m_wstrb(wstrb_m1),
            .m_wlast(wlast_m1), .m_wvalid(wvalid_m1), .m_wready(wready_m1),
            .m_bresp(bresp_m1), .m_bvalid(bvalid_m1), .m_bready(bready_m1), .m_bid(bid_m1)
        );
    end else begin : g_one_port
        // single port: M0 carries both reads and writes
        dma350_axi_node #(.N(NC), .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
                          .ID_WIDTH(ID_WIDTH), .ARUSER_W(ARUSER_W), .AWUSER_W(AWUSER_W),
                          .ISSUING_CAP(ISSUING_CAP))
        u_node (
            .clk(clk), .resetn(resetn), .ch_prio(c_chprio),
            .ch_arvalid(c_arvalid), .ch_arready(arready0), .ch_araddr(c_araddr),
            .ch_arlen(c_arlen), .ch_arsize(c_arsize), .ch_arburst(c_arburst),
            .ch_aruser(c_aruser),
            .ch_rvalid(rvalid0), .ch_rready(c_rready),
            .ch_rdata(c_rdata_m0), .ch_rresp(c_rresp_m0), .ch_rpoison(c_rpoison_m0),
            .ch_rlast(c_rlast_m0),
            .ch_awvalid(c_awvalid), .ch_awready(awready0), .ch_awaddr(c_awaddr),
            .ch_awlen(c_awlen), .ch_awsize(c_awsize), .ch_awburst(c_awburst),
            .ch_awuser(c_awuser),
            .ch_wvalid(c_wvalid), .ch_wready(wready0), .ch_wdata(c_wdata),
            .ch_wstrb(c_wstrb), .ch_wlast(c_wlast),
            .ch_bvalid(bvalid0), .ch_bready(c_bready), .ch_bresp(c_bresp_m0),
            .m_araddr(araddr_m0), .m_arlen(arlen_m0), .m_arsize(arsize_m0),
            .m_arburst(m0_arburst),
            .m_arid(arid_m0), .m_aruser(m0_aruser), .m_arvalid(arvalid_m0),
            .m_arready(arready_m0), .m_rdata(rdata_m0), .m_rresp(rresp_m0),
            .m_rpoison(poison_m0), .m_rid(rid_m0),
            .m_rlast(rlast_m0), .m_rvalid(rvalid_m0), .m_rready(rready_m0),
            .m_awaddr(awaddr_m0), .m_awlen(awlen_m0), .m_awsize(awsize_m0),
            .m_awburst(m0_awburst),
            .m_awid(awid_m0), .m_awuser(m0_awuser), .m_awvalid(awvalid_m0),
            .m_awready(awready_m0), .m_wdata(wdata_m0), .m_wstrb(wstrb_m0),
            .m_wlast(wlast_m0), .m_wvalid(wvalid_m0), .m_wready(wready_m0),
            .m_bresp(bresp_m0), .m_bvalid(bvalid_m0), .m_bready(bready_m0), .m_bid(bid_m0)
        );
        assign m1_arburst = 2'b00; assign m1_awburst = 2'b00;
        // M1 node absent: tie its channel-return nets low so the OR-combine and
        // the mgr_vec data mux (forced to M0 here) resolve to M0 only.
        assign arready1 = '0; assign rvalid1 = '0; assign awready1 = '0;
        assign wready1  = '0; assign bvalid1 = '0;
        assign c_rdata_m1 = '0; assign c_rresp_m1 = '0; assign c_rlast_m1 = 1'b0;
        assign c_rpoison_m1 = 1'b0; assign c_bresp_m1 = '0;

        // M1 unused: tie off all outputs
        assign awakeup_m1=1'b0; assign awvalid_m1=1'b0; assign awaddr_m1='0;
        assign awburst_m1='0; assign awid_m1='0; assign awlen_m1='0; assign awsize_m1='0;
        assign awqos_m1='0; assign awprot_m1='0; assign awcache_m1='0; assign awdomain_m1='0;
        assign awinner_m1='0; assign awchid_m1='0; assign awchidvalid_m1=1'b0;
        assign arvalid_m1=1'b0; assign araddr_m1='0; assign arburst_m1='0; assign arid_m1='0;
        assign arlen_m1='0; assign arsize_m1='0; assign arqos_m1='0; assign arprot_m1='0;
        assign arcache_m1='0; assign ardomain_m1='0; assign arinner_m1='0; assign archid_m1='0;
        assign archidvalid_m1=1'b0; assign arcmdlink_m1=1'b0;
        assign wvalid_m1=1'b0; assign wlast_m1=1'b0; assign wstrb_m1='0; assign wdata_m1='0;
        assign rready_m1=1'b0; assign bready_m1=1'b0;
        assign m1_aruser = '0; assign m1_awuser = '0;
    end endgenerate

    // =====================================================================
    // Unpack AXI user bundles onto the physical AXI5 user pins
    // =====================================================================
    // M0
    assign arprot_m0     = m0_aruser[2:0];
    assign arcache_m0    = m0_aruser[6:3];
    assign ardomain_m0   = m0_aruser[8:7];
    assign arinner_m0    = m0_aruser[12:9];
    assign arqos_m0      = m0_aruser[16:13];
    assign archid_m0     = m0_aruser[17 +: CHIDNZ];
    assign arcmdlink_m0  = m0_aruser[17 + CHIDNZ];
    assign archidvalid_m0= (CHID_WIDTH > 0) & arvalid_m0;
    assign arburst_m0    = m0_arburst;
    assign awprot_m0     = m0_awuser[2:0];
    assign awcache_m0    = m0_awuser[6:3];
    assign awdomain_m0   = m0_awuser[8:7];
    assign awinner_m0    = m0_awuser[12:9];
    assign awqos_m0      = m0_awuser[16:13];
    assign awchid_m0     = m0_awuser[17 +: CHIDNZ];
    assign awchidvalid_m0= (CHID_WIDTH > 0) & awvalid_m0;
    assign awburst_m0    = m0_awburst;
    assign awakeup_m0    = |c_busy | pwakeup;

    generate if (AXI5_M1_PRESENT != 0) begin : g_m1_user
        assign arprot_m1     = m1_aruser[2:0];
        assign arcache_m1    = m1_aruser[6:3];
        assign ardomain_m1   = m1_aruser[8:7];
        assign arinner_m1    = m1_aruser[12:9];
        assign arqos_m1      = m1_aruser[16:13];
        assign archid_m1     = m1_aruser[17 +: CHIDNZ];
        assign arcmdlink_m1  = m1_aruser[17 + CHIDNZ];
        assign archidvalid_m1= (CHID_WIDTH > 0) & arvalid_m1;
        assign arburst_m1    = m1_arburst;
        assign awprot_m1     = m1_awuser[2:0];
        assign awcache_m1    = m1_awuser[6:3];
        assign awdomain_m1   = m1_awuser[8:7];
        assign awinner_m1    = m1_awuser[12:9];
        assign awqos_m1      = m1_awuser[16:13];
        assign awchid_m1     = m1_awuser[17 +: CHIDNZ];
        assign awchidvalid_m1= (CHID_WIDTH > 0) & awvalid_m1;
        assign awburst_m1    = m1_awburst;
        assign awakeup_m1    = |c_busy;
    end endgenerate

    // Note: aclken_m*/pclken, boot_memattr and boot_shareattr are part of the
    // Appendix A interface and are sampled but not propagated by this
    // behavioral model (no clock-gating datapath). They remain on the port
    // list for spec completeness. (rpoison/rid/bid ARE consumed by the AXI
    // node and channels; pdebug gates the security-violation error/IRQ.)

    // =====================================================================
    // Q-Channel / P-Channel low-power controllers
    // =====================================================================
    wire dmac_busy = |c_busy;

    dma350_qchannel u_qch (
        .clk(clk), .resetn(resetn),
        .clk_qreqn(clk_qreqn), .clk_qacceptn(clk_qacceptn),
        .clk_qdeny(clk_qdeny), .clk_qactive(clk_qactive),
        .busy(dmac_busy), .wakeup(pwakeup | (|c_irq))
    );

    // power policy controls: DISMINPWR (NSEC/SEC_CTRL[31:30]) forbids the OFF
    // state when a nonzero minimum power level is configured; retention while
    // idle stays enabled. An accepted WARM_RST state pauses all channels
    // (pch_warm feeds the all-channel pause combine above, TRM 5.9.1.1).
    wire pch_dis_min = (|nsec_ctrl_q[31:30])
                     | ((SECEXT_PRESENT != 0) & (|sec_ctrl_q[31:30]));
    dma350_pchannel u_pch (
        .clk(clk), .resetn(resetn),
        .preq(preq), .pstate(pstate),
        .paccept(paccept), .pdeny(pdeny), .pactive(pactive),
        .busy(dmac_busy), .dis_min_pwr(pch_dis_min), .idle_reten(1'b1),
        .in_warm_rst(pch_warm)
    );

endmodule

`default_nettype wire
