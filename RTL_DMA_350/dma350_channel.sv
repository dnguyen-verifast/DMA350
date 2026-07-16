//-----------------------------------------------------------------------------
// dma350_channel.sv
//
// One DMA-350 channel: command engine + AXI5 read/write managers + deep
// per-channel data FIFO with byte-accurate realignment + optional AXI4-Stream
// expansion + automatic restart + command linking + pause/resume + trigger
// flow-control + halt(CTI)/all-channel stop & pause.
//
// Datapath (byte accurate, TRM faithful):
//   * AxSIZE is driven from TRANSIZE (per side, clamped to the bus width), so a
//     transfer of unit 2^TRANSIZE appears on the bus as 2^AxSIZE-byte beats.
//   * A FIFO_DEPTH-word per-channel byte FIFO (dma350_byte_fifo) decouples the
//     read and write sides. The read side pushes the valid, lane-compacted
//     source bytes; the write side pops and re-places them on the destination
//     byte lanes, so arbitrary source vs destination byte alignment is handled
//     and WSTRB marks exactly the valid bytes (no over-write of trailing bytes
//     for non-bus-multiple sizes).
//   * AxBURST is INCR or FIXED per side (fixed-address peripheral access).
//   * 2D transfers iterate YSIZE lines, advancing the source/destination line
//     base by the programmed strides between lines.
//   * A read SLVERR/DECERR or an R-channel poison flags a channel error.
//
// Assumptions: start/line addresses are aligned to the transfer unit
// (2^TRANSIZE), as required by DMA-350; DATA_WIDTH is a multiple of 32.
//-----------------------------------------------------------------------------
`default_nettype none

module dma350_channel import dma350_pkg::*; #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int FIFO_DEPTH = 16,
    parameter int BURST_SIZE = 16,     // retained for compatibility (unused)
    parameter int MAX_BYTES  = 1024,   // DMA-350 max bytes per burst
    parameter int AWQ_DEPTH  = 4       // write-burst issuing capability
)(
    input  wire                      aclk,
    input  wire                      aresetn,

    // ---- command requests ----
    input  wire                      enablecmd,
    input  wire                      stopcmd,
    input  wire                      pausecmd,
    input  wire                      resumecmd,
    input  wire                      disablecmd,
    input  wire                      clearcmd,
    input  wire                      swtrigin_src,
    input  wire                      swtrigin_des,

    // ---- boot loader (channel 0) ----
    input  wire                      boot_req,
    input  wire [ADDR_WIDTH-1:0]     boot_addr_i,

    // ---- system-level control ----
    input  wire                      halt_req,
    input  wire                      restart_req,
    input  wire                      allstop,
    input  wire                      allpause,

    // ---- status ----
    output reg                       ch_enabled,
    output reg                       fsm_done,
    output reg                       fsm_stopped,
    output reg                       fsm_disabled,
    output reg                       fsm_error,
    output reg                       fsm_paused,
    output reg                       fsm_resumewait,
    output reg                       fsm_srctrigwait,
    output reg                       fsm_destrigwait,
    output reg                       fsm_trigoutwait,
    output reg                       clr_enablecmd,
    output wire                      busy,
    output reg  [31:0]               errinfo,       // CH_ERRINFO cause (Table 5-9)

    // ---- configuration ----
    input  wire [ADDR_WIDTH-1:0]     srcaddr,
    input  wire [ADDR_WIDTH-1:0]     desaddr,
    input  wire [31:0]               src_xsize,     // source items (XSIZE+HI)
    input  wire [31:0]               des_xsize,     // destination items
    input  wire [2:0]                src_transize,  // log2 source unit bytes
    input  wire [2:0]                des_transize,  // log2 destination unit bytes
    input  wire signed [15:0]        src_xaddrinc,  // source element increment (signed,
    input  wire signed [15:0]        des_xaddrinc,  //   0 = fixed address, TRM 5.2.3)
    input  wire [15:0]               ysize,         // 2D line count
    input  wire [ADDR_WIDTH-1:0]     src_stride,    // 2D source line stride (bytes)
    input  wire [ADDR_WIDTH-1:0]     des_stride,    // 2D destination line stride
    input  wire                      wrap_en,       // XTYPE = wrap (cycle source)
    input  wire                      fill_en,       // XTYPE = fill
    input  wire [31:0]               fillval,
    input  wire [31:0]               srctmplt,      // source template bit-mask
    input  wire [31:0]               destmplt,      // destination template bit-mask
    input  wire [4:0]                srctmpltsize,  // SRCTMPLTSIZE (0 = disabled)
    input  wire [4:0]                destmpltsize,  // DESTMPLTSIZE (0 = disabled)
    input  wire                      usestream,
    input  wire [2:0]                xtype,         // CH_CTRL.XTYPE (000 = empty cmd)
    input  wire [2:0]                donetype,      // CH_CTRL.DONETYPE
    input  wire [2:0]                regreloadtype,
    input  wire                      donepauseen,
    input  wire [15:0]               cmdrestartcnt,
    input  wire                      cmdrestartinfen,
    input  wire [ADDR_WIDTH-1:0]     linkaddr,
    input  wire                      linkaddren,
    input  wire                      srctrigin_en,
    input  wire [1:0]                srctrigin_mode,      // TRM TRIGINMODE
    input  wire [7:0]                src_trigin_blksize,  // TRIGINBLKSIZE (block-1)
    input  wire                      destrigin_en,
    input  wire [1:0]                destrigin_mode,
    input  wire [7:0]                des_trigin_blksize,
    input  wire                      trigout_en,
    input  wire [1:0]                swtrigin_srctype,    // CH_CMD SW trigger types
    input  wire [1:0]                swtrigin_destype,
    input  wire                      swtrigout_ack,       // CH_CMD.SWTRIGOUTACK
    input  wire [3:0]                src_maxburstlen,     // TRANSCFG MAXBURSTLEN
    input  wire [3:0]                des_maxburstlen,
    input  wire                      trigcfg_regval_err,  // trig selector range err

    input  wire [ADDR_WIDTH-1:0]     src_orig,
    input  wire [ADDR_WIDTH-1:0]     des_orig,
    input  wire [31:0]               srcx_orig,
    input  wire [31:0]               desx_orig,

    // ---- live write-back ----
    output reg                       live_we,
    output reg  [ADDR_WIDTH-1:0]     live_srcaddr,
    output reg  [ADDR_WIDTH-1:0]     live_desaddr,
    output reg  [31:0]               live_src_xsize,
    output reg  [31:0]               live_des_xsize,

    // ---- command-link internal register write (replays the descriptor) ----
    output reg                       iwr_en,
    output reg  [7:0]                iwr_off,
    output reg  [31:0]               iwr_data,
    output reg                       iwr_regclear,

    // ---- trigger matrix handshake ----
    input  wire                      src_trig_pending,
    input  wire [1:0]                src_trig_type,
    output reg                       src_trig_take,
    output reg                       src_trig_take_last,   // ack with LAST OKAY
    input  wire                      des_trig_pending,
    input  wire [1:0]                des_trig_type,
    output reg                       des_trig_take,
    output reg                       des_trig_take_last,
    output reg                       trigout_start,
    input  wire                      trigout_done,

    // ---- AXI5 read manager ----
    output reg  [ADDR_WIDTH-1:0]     m_axi_araddr,
    output reg  [7:0]                m_axi_arlen,
    output reg  [2:0]                m_axi_arsize,
    output reg  [1:0]                m_axi_arburst,
    output reg                       m_axi_arvalid,
    output wire                      m_axi_arcmdlink,
    input  wire                      m_axi_arready,
    input  wire [DATA_WIDTH-1:0]     m_axi_rdata,
    input  wire [1:0]                m_axi_rresp,
    input  wire                      m_axi_rpoison,
    input  wire                      m_axi_rlast,
    input  wire                      m_axi_rvalid,
    output wire                      m_axi_rready,

    // ---- AXI5 write manager ----
    output reg  [ADDR_WIDTH-1:0]     m_axi_awaddr,
    output reg  [7:0]                m_axi_awlen,
    output reg  [2:0]                m_axi_awsize,
    output reg  [1:0]                m_axi_awburst,
    output reg                       m_axi_awvalid,
    input  wire                      m_axi_awready,
    output wire [DATA_WIDTH-1:0]     m_axi_wdata,
    output wire [DATA_WIDTH/8-1:0]   m_axi_wstrb,
    output wire                      m_axi_wlast,
    output wire                      m_axi_wvalid,
    input  wire                      m_axi_wready,
    input  wire [1:0]                m_axi_bresp,
    input  wire                      m_axi_bvalid,
    output reg                       m_axi_bready,

    // ---- AXI4-Stream expansion ----
    output wire [DATA_WIDTH-1:0]     m_axis_out_tdata,
    output wire                      m_axis_out_tvalid,
    input  wire                      m_axis_out_tready,
    output wire                      m_axis_out_tlast,
    input  wire [DATA_WIDTH-1:0]     s_axis_in_tdata,
    input  wire [DATA_WIDTH/8-1:0]   s_axis_in_tstrb,
    input  wire                      s_axis_in_tvalid,
    output wire                      s_axis_in_tready,
    input  wire                      s_axis_in_tlast,
    output reg                       s_axis_in_flush,   // discard-data hint

    // ---- trigger-selection error indications (from the trigger matrix) ----
    input  wire                      srctrigin_sel_err,
    input  wire                      destrigin_sel_err,
    input  wire                      trigout_sel_err
);
    localparam int BPB     = DATA_WIDTH/8;
    localparam int LOG2BPB = $clog2(BPB);
    localparam int FBYTES  = FIFO_DEPTH * BPB;      // data-FIFO capacity (bytes)
    localparam int FCW     = $clog2(FBYTES+1);      // FIFO byte-count width
    localparam int NBW     = $clog2(BPB+1);         // per-beat byte-count width

    // =====================================================================
    // FSM state (declared early so datapath gates can reference it)
    // =====================================================================
    typedef enum logic [4:0] {
        D_DISABLED, D_CFG, D_TRIG_WAIT, D_XFER, D_PAUSED, D_NEXTLINE, D_DRAIN,
        D_TRIGOUT, D_DONE, D_RESTART,
        D_LINK_AR, D_LINK_R, D_LINK_APPLY, D_LINK_WAIT,
        D_DONEPAUSE, D_ERR, D_STOPPED
    } dst_t;
    dst_t ds;
    assign busy = (ds != D_DISABLED);

    reg  paused_req;
    reg  disable_req;      // graceful DISABLECMD: finish current cmd, no link
    reg  empty_q;          // current command is an empty command (XTYPE=disable)
    wire pause_eff = paused_req | halt_req | allpause;
    wire stop_eff  = stopcmd | allstop;

    // abort drain (stop/error): in-flight AXI transactions must complete to
    // avoid deadlock — remaining reads are drained and the W beats of any
    // already-accepted AW are sent with WSTRB=0 until all B responses return.
    wire abort_active = (ds == D_ERR) | (ds == D_STOPPED);

    // ---- datapath state declared ahead of first reference (strict tools) ----
    reg                  rd_active, wr_active, link_rd_active;
    reg [15:0]           outstanding_b;   // AWs accepted, B not yet received
    reg [5:0]            rd_out_ch;       // ARs accepted, RLAST not yet received

    // =====================================================================
    // Latched per-command configuration
    // =====================================================================
    reg [2:0]  axsize_s_q, axsize_d_q;
    reg [12:0] bbs_q, bbd_q;             // bytes per beat (source/dest)
    reg        sfixed_q, dfixed_q;
    reg        use_stream_q, fill_q;
    reg [31:0] fillval_q;
    reg [15:0] y_rem;
    reg [ADDR_WIDTH-1:0] src_line_base, des_line_base;
    reg [ADDR_WIDTH-1:0] sstride_q, dstride_q;
    reg [31:0] line_src_bytes, line_des_bytes;   // bytes per line
    // 1D WRAP (XTYPE=wrap) is modelled as a 2D-style loop: each "line" re-reads
    // the source block (source stride 0) into the next destination block; the
    // final line is truncated so exactly DES bytes are written.
    reg        wrap_q;
    reg [31:0] wrap_last_des_q;                  // bytes written by the last pass

    // -------- single-element ("gen") addressing for template / strided -------
    // Per TRM 5.3.3 templated transfers always use single transfers; non-unit or
    // negative SRC/DESXADDRINC strides are also non-contiguous. In gen mode the
    // engine issues one 1-beat AXI access per element at a computed address,
    // single-outstanding, while the contiguous/fixed case keeps the fast bursts.
    // (Trigger flow-control credits/gates are declared after the burst
    // generators below, once rb_*/wb_* and the line counters are in scope.)

    reg                  gen_s_q, gen_d_q;       // source / dest gen mode
    reg signed [ADDR_WIDTH-1:0] stride_s_q, stride_d_q;  // signed byte stride/pos
    reg [4:0]            stsize_s_q, stsize_d_q; // template length-1 (0 = none)
    reg [31:0]           stmplt_s_q, stmplt_d_q; // template masks
    reg [ADDR_WIDTH-1:0] rd_elem_addr, wr_elem_addr;     // current element addr
    reg [4:0]            rd_pos, wr_pos;         // template position
    reg                  gen_rd_busy;            // a gen read AR/R is in flight

    // current-line running counters
    reg [ADDR_WIDTH-1:0] rd_byte_addr, wr_byte_addr;
    reg [31:0]           rd_rem, wr_rem;          // bytes remaining in the line

    // helper: clamp transize to bus width -> AxSIZE
    function automatic [2:0] axsz(input [2:0] tsz);
        axsz = (tsz > LOG2BPB[2:0]) ? LOG2BPB[2:0] : tsz;
    endfunction

    // byte masks
    function automatic [DATA_WIDTH-1:0] bmask(input int n);
        if (n >= BPB) bmask = {DATA_WIDTH{1'b1}};
        else          bmask = ({{DATA_WIDTH-1{1'b0}},1'b1} << (n*8)) - 1;
    endfunction
    function automatic [BPB-1:0] smask(input int n);
        if (n >= BPB) smask = {BPB{1'b1}};
        else          smask = ({{BPB-1{1'b0}},1'b1} << n) - 1;
    endfunction

    // gen-mode template selection: the current source/destination element
    // position transfers if templating is disabled or its template bit is set.
    wire rd_tmpl_sel = (stsize_s_q == 5'd0) | stmplt_s_q[rd_pos];
    wire wr_tmpl_sel = (stsize_d_q == 5'd0) | stmplt_d_q[wr_pos];
    // next template position (wraps at template length = size+1)
    wire [4:0] rd_pos_nxt = (rd_pos == stsize_s_q) ? 5'd0 : (rd_pos + 5'd1);
    wire [4:0] wr_pos_nxt = (wr_pos == stsize_d_q) ? 5'd0 : (wr_pos + 5'd1);

    // =====================================================================
    // Per-channel data FIFOs (byte gearbox: deep buffering + realignment).
    //   u_rfifo : read side — push = lane-compacted read bytes; pop = stream-out
    //             (stream mode) or the write side (non-stream).
    //   u_wfifo : write side — push = stream-in; pop = write  (stream mode only).
    // Each holds FIFO_DEPTH bus-words, as per the TRM per-channel buffer.
    // =====================================================================
    reg                    fifo_flush;
    wire [NBW-1:0]         rf_push_n, rf_pop_n, wf_push_n, wf_pop_n;
    wire [DATA_WIDTH-1:0]  rf_push_data, rf_pop_data, wf_push_data, wf_pop_data;
    wire                   rf_push_en, rf_pop_en, wf_push_en, wf_pop_en;
    wire [FCW-1:0]         rf_count, wf_count;

    dma350_byte_fifo #(.WBYTES(BPB), .DEPTH(FBYTES)) u_rfifo (
        .clk(aclk), .rstn(aresetn), .flush(fifo_flush),
        .push_en(rf_push_en), .push_n(rf_push_n), .push_data(rf_push_data),
        .pop_en(rf_pop_en), .pop_n(rf_pop_n), .pop_data(rf_pop_data),
        .count(rf_count));
    dma350_byte_fifo #(.WBYTES(BPB), .DEPTH(FBYTES)) u_wfifo (
        .clk(aclk), .rstn(aresetn), .flush(fifo_flush),
        .push_en(wf_push_en), .push_n(wf_push_n), .push_data(wf_push_data),
        .pop_en(wf_pop_en), .pop_n(wf_pop_n), .pop_data(wf_pop_data),
        .count(wf_count));

    // current beat byte counts
    wire [12:0] nbytes_s = (rd_rem >= {19'd0,bbs_q}) ? bbs_q : rd_rem[12:0];
    wire [12:0] nbytes_d = (wr_rem >= {19'd0,bbd_q}) ? bbd_q : wr_rem[12:0];

    // lane offsets within the bus word
    wire [LOG2BPB-1:0] src_lane = rd_byte_addr[LOG2BPB-1:0];
    wire [LOG2BPB-1:0] dst_lane = wr_byte_addr[LOG2BPB-1:0];

    // =====================================================================
    // Burst generators (addresses for AR / AW)
    // =====================================================================
    reg                   rb_start, wb_start;
    wire                  rb_valid, wb_valid;
    wire [ADDR_WIDTH-1:0] rb_addr,  wb_addr;
    wire [7:0]            rb_len,   wb_len;
    wire [8:0]            rb_beats, wb_beats;
    wire [1:0]            rb_type,  wb_type;
    wire                  rb_busy, rb_done, wb_busy, wb_done;
    reg  [ADDR_WIDTH-1:0] rb_addr_in, wb_addr_in;
    reg  [23:0]           rb_beats_in, wb_beats_in;

    dma350_burst #(.C_ADDR_WIDTH(ADDR_WIDTH), .C_BEATS_WIDTH(24), .MAX_BYTES(MAX_BYTES))
    u_rburst (
        .aclk(aclk), .aresetn(aresetn),
        .start(rb_start), .addr_in(rb_addr_in), .beats_in(rb_beats_in),
        .size(axsize_s_q), .fixed(sfixed_q),
        .max_beats({5'd0, src_maxburstlen} + 9'd1),   // SRCMAXBURSTLEN + 1
        .burst_valid(rb_valid), .burst_addr(rb_addr), .burst_len(rb_len),
        .burst_beats(rb_beats), .burst_type(rb_type),
        .burst_ready(m_axi_arvalid & m_axi_arready & ~link_rd_active),
        .busy(rb_busy), .done(rb_done));

    dma350_burst #(.C_ADDR_WIDTH(ADDR_WIDTH), .C_BEATS_WIDTH(24), .MAX_BYTES(MAX_BYTES))
    u_wburst (
        .aclk(aclk), .aresetn(aresetn),
        .start(wb_start), .addr_in(wb_addr_in), .beats_in(wb_beats_in),
        .size(axsize_d_q), .fixed(dfixed_q),
        .max_beats({5'd0, des_maxburstlen} + 9'd1),   // DESMAXBURSTLEN + 1
        .burst_valid(wb_valid), .burst_addr(wb_addr), .burst_len(wb_len),
        .burst_beats(wb_beats), .burst_type(wb_type),
        .burst_ready(m_axi_awvalid & m_axi_awready),
        .busy(wb_busy), .done(wb_done));

    // =====================================================================
    // Trigger flow control (TRM 5.4.1.2). In the flow-control TRIGINMODEs each
    // trigger releases a credit of transfers: SINGLE = 1, BLOCK =
    // TRIGINBLKSIZE+1; a LAST request additionally closes the command after its
    // block. Command mode (and internal triggers) releases the whole command.
    // Source credits gate reads, destination credits gate writes. Software
    // trigger requests (CH_CMD) can substitute for hardware requests.
    // =====================================================================
    reg [16:0]           rd_credit, wr_credit;
    reg                  rd_unlimited, wr_unlimited;
    wire                 flowctrl_s = srctrigin_en & srctrigin_mode[1];
    wire                 flowctrl_d = destrigin_en & destrigin_mode[1];
    wire [16:0]          blkcred_s  = {9'd0, src_trigin_blksize} + 17'd1;
    wire [16:0]          blkcred_d  = {9'd0, des_trigin_blksize} + 17'd1;

    // per-element / whole-burst credit checks
    wire rd_cred_ok  = ~flowctrl_s | rd_unlimited | (rd_credit != 17'd0);
    wire rd_cred_bok = ~flowctrl_s | rd_unlimited | (rd_credit >= {8'd0, rb_beats});
    wire wr_cred_ok  = ~flowctrl_d | wr_unlimited | (wr_credit != 17'd0);
    wire wr_cred_bok = ~flowctrl_d | wr_unlimited | (wr_credit >= {8'd0, wb_beats});

    // a new trigger grant is needed when credit cannot cover the next access
    wire fc_need   = flowctrl_s & ~rd_unlimited & (rd_rem != 0) &
                     ( (gen_s_q  & (rd_credit == 17'd0))
                     | (~gen_s_q & rb_valid & (rd_credit < {8'd0, rb_beats})) );
    wire fc_need_d = flowctrl_d & ~wr_unlimited & (wr_rem != 0) &
                     ( (gen_d_q  & (wr_credit == 17'd0))
                     | (~gen_d_q & wb_valid & (wr_credit < {8'd0, wb_beats})) );

    // mid-transfer grants: HW pending request, or SW trigger request as backup
    wire [1:0] fc_type_s = src_trig_pending ? src_trig_type : swtrigin_srctype;
    wire [1:0] fc_type_d = des_trig_pending ? des_trig_type : swtrigin_destype;
    wire fc_take_mid   = (ds==D_XFER) & fc_need   & src_trig_pending & ~src_trig_take;
    wire fc_sw_mid     = (ds==D_XFER) & fc_need   & ~src_trig_pending & swtrigin_src;
    wire fc_grant_s    = fc_take_mid | fc_sw_mid;
    wire fc_take_mid_d = (ds==D_XFER) & fc_need_d & des_trig_pending & ~des_trig_take;
    wire fc_sw_mid_d   = (ds==D_XFER) & fc_need_d & ~des_trig_pending & swtrigin_des;
    wire fc_grant_d    = fc_take_mid_d | fc_sw_mid_d;
    wire [16:0] fc_cred_s  = fc_type_s[1] ? blkcred_s : 17'd1;   // BLOCK vs SINGLE
    wire [16:0] fc_cred_d  = fc_type_d[1] ? blkcred_d : 17'd1;
    wire [31:0] fc_bytes_s = {15'd0, fc_cred_s} << axsize_s_q;
    wire [31:0] fc_bytes_d = {15'd0, fc_cred_d} << axsize_d_q;

    // =====================================================================
    // Handshakes
    // =====================================================================
    wire ar_fire = m_axi_arvalid & m_axi_arready;
    wire r_fire  = m_axi_rvalid  & m_axi_rready;
    wire aw_fire = m_axi_awvalid & m_axi_awready;
    wire w_fire  = m_axi_wvalid  & m_axi_wready;
    wire b_fire  = m_axi_bvalid  & m_axi_bready;

    assign m_axi_arcmdlink = link_rd_active;

    // Pause stops issuing NEW AR/AW bursts (handled in the FSM); in-flight data
    // beats are allowed to drain so AXI VALID is never dropped mid-handshake.
    // FILL still reads its SRCXSIZE source bytes (rd_active reflects sbytes!=0);
    // the FILLVAL padding only substitutes for the source *shortfall*, so reads
    // must NOT be suppressed in fill mode.
    wire rd_run  = rd_active & (rd_rem != 0);             // accepting read beats
    wire rf_room = ((FBYTES[FCW-1:0] - rf_count) >= BPB[FCW-1:0]); // room for a beat

    // drain (discard) any straggler read beats while finishing a line/command
    // (e.g. SRCXSIZE > DESXSIZE) or aborting, so the shared R bus never blocks.
    wire rd_draining = abort_active | (ds == D_DRAIN) | (ds == D_NEXTLINE);
    assign m_axi_rready = (rd_run & rf_room) | link_rd_active | rd_draining;
    wire push_fire = r_fire & rd_active & ~link_rd_active & ~rd_draining;

    // compacted source bytes for this read beat -> read FIFO
    wire [DATA_WIDTH-1:0] compact = (m_axi_rdata >> ({3'd0,src_lane}*8)) & bmask(nbytes_s);
    assign rf_push_en   = push_fire;
    assign rf_push_n    = nbytes_s[NBW-1:0];
    assign rf_push_data = compact;

    // =====================================================================
    // Stream-out path (read FIFO -> DPU)
    // =====================================================================
    reg str_out_active, str_in_active;
    wire so_run   = use_stream_q & str_out_active;
    wire rd_line_done = (rd_rem == 0);
    wire so_avail = (rf_count >= BPB[FCW-1:0]) | ((rf_count != 0) & rd_line_done);
    wire [12:0] so_nbytes = (rf_count >= BPB[FCW-1:0]) ? BPB[12:0] : rf_count[12:0];
    assign m_axis_out_tvalid = so_run & so_avail;
    assign m_axis_out_tdata  = rf_pop_data;
    assign m_axis_out_tlast  = so_run & rd_line_done & (rf_count <= BPB[FCW-1:0]) & (y_rem <= 16'd1);
    wire so_fire = m_axis_out_tvalid & m_axis_out_tready;

    // =====================================================================
    // Stream-in path (DPU -> write FIFO)
    // =====================================================================
    wire si_run  = use_stream_q & str_in_active;
    wire wf_room = ((FBYTES[FCW-1:0] - wf_count) >= BPB[FCW-1:0]);
    assign s_axis_in_tready = si_run & wf_room;
    wire si_fire = s_axis_in_tvalid & s_axis_in_tready;
    assign wf_push_en   = si_fire;
    assign wf_push_n    = BPB[NBW-1:0];
    assign wf_push_data = s_axis_in_tdata;

    // =====================================================================
    // Write source select and write beat formation
    // =====================================================================
    wire [FCW-1:0]        wsrc_count = use_stream_q ? wf_count : rf_count;
    wire [DATA_WIDTH-1:0] wsrc_low   = use_stream_q ? wf_pop_data : rf_pop_data;

    // FILL (XTYPE=fill): once all source data has been read and drained, the
    // remaining destination beats are written with the FILLVAL pattern. Until
    // then the read FIFO supplies the data normally.
    wire src_drained = (rd_rem == 0) & (rd_out_ch == 0) & (rf_count == 0);
    wire w_use_fifo  = (wsrc_count >= nbytes_d[FCW-1:0]);
    wire w_use_fill  = fill_q & ~w_use_fifo & src_drained;
    wire w_avail     = w_use_fifo | w_use_fill;

    // FIFO pop wiring: pop only when the write actually consumes FIFO data
    // (not when substituting FILLVAL, not while aborting, not for stream-out).
    assign rf_pop_en = ~abort_active & (use_stream_q ? so_fire
                                                     : (w_fire & w_use_fifo));
    assign rf_pop_n  = use_stream_q ? so_nbytes[NBW-1:0] : nbytes_d[NBW-1:0];
    assign wf_pop_en = ~abort_active & use_stream_q & w_fire & w_use_fifo;
    assign wf_pop_n  = nbytes_d[NBW-1:0];

    // Write-burst beat-count FIFO: lets the channel issue several AWs ahead of
    // the W data (issuing capability). Each accepted AW pushes its beat count;
    // the W engine streams the head burst, asserting WLAST on its last beat.
    localparam int AQCW = $clog2(AWQ_DEPTH+1);
    reg  [8:0]      awq_mem [AWQ_DEPTH];
    reg  [AQCW-1:0] awq_cnt, awq_head, awq_tail;
    wire            awq_full  = (awq_cnt == AWQ_DEPTH[AQCW-1:0]);
    reg  [8:0]      w_left;          // beats remaining in the current W burst

    // W-beat emission. Three sources of a beat:
    //   * in-line  : the active line still has destination bytes and data is
    //                available in the FIFO (or FILLVAL) -> REAL data + strobe.
    //   * end-of-line / end-of-transfer drain (D_NEXTLINE / D_DRAIN, NOT abort):
    //                an AW was accepted whose W beats trail into the drain state
    //                (e.g. WRAP/2D passes are pipelined). These carry REAL data,
    //                so they must still wait for w_avail and drive REAL strobe -
    //                zeroing them here would silently drop the payload.
    //   * abort (D_ERR / D_STOPPED): the accepted AW must be completed to free
    //                the subordinate, but the data is discarded -> dummy beats
    //                (WSTRB = 0), fired regardless of w_avail so we never hang.
    wire draining_norm = (ds == D_DRAIN) | (ds == D_NEXTLINE);
    wire w_active = (w_left != 9'd0) &
                    ( (wr_active     & w_avail & (wr_rem != 0))   // in-line
                    | (draining_norm & w_avail)                   // trailing real beats
                    | abort_active );                             // dummy flush

    // fill word: replicate the 32-bit fill value across the bus
    wire [DATA_WIDTH-1:0] fill_word = {(DATA_WIDTH/32){fillval_q}};

    assign m_axi_wvalid = w_active;
    assign m_axi_wdata  = ( (w_use_fifo ? (wsrc_low & bmask(nbytes_d)) : fill_word)
                            << ({3'd0,dst_lane}*8) );
    // strobe follows the DATA, not the FSM: only abort (no real payload) masks
    // it. Every non-abort beat is gated on w_avail, so it always carries data.
    assign m_axi_wstrb  = abort_active ? '0 : (smask(nbytes_d) << dst_lane);
    assign m_axi_wlast  = w_active & (w_left == 9'd1);

    // =====================================================================
    // FSM
    // =====================================================================
    // (outstanding_b / rd_out_ch are declared with the early datapath state)
    reg        err_pending;
    reg        trigout_started;
    reg [15:0] restart_cnt;
    reg        restart_inf;

    reg [ADDR_WIDTH-1:0] link_fetch_addr;
    reg [5:0]            link_word_idx;
    reg [31:0]           link_hdr;
    reg [31:0]           link_words [0:31];
    reg [5:0]            link_words_needed, link_words_got;
    reg [5:0]            apply_b, apply_idx;     // command-link replay walker
    reg                  apply_first;

    // number of data words a command-link header implies = set bits that carry
    // a word (REGCLEAR bit0 and reserved bits 1/23/25/27 carry none).
    function automatic [5:0] count_link_words(input [31:0] hdr);
        logic [5:0] c; c = 0;
        for (int k=1;k<32;k++)
            if (hdr[k] && (link_bit_off(k) != 8'hFF)) c += 1'b1;
        return c;
    endfunction

    // compute beats-per-line for the latched config
    function automatic [23:0] beats_of(input [31:0] bytes, input [2:0] sz);
        beats_of = (bytes + ((32'd1<<sz)-1)) >> sz;     // ceil(bytes / 2^sz)
    endfunction

    localparam [31:0] CTRL_RST_LOCAL = 32'h00200200;

    // kick the read/write datapath for a line. In gen mode (template / strided)
    // the burst engine is NOT used — addresses come from rd/wr_elem_addr.
    task automatic start_line(
        input [ADDR_WIDTH-1:0] sbase, input [ADDR_WIDTH-1:0] dbase,
        input [31:0] sbytes, input [31:0] dbytes,
        input [2:0] szs, input [2:0] szd, input strm, input fil,
        input gens, input gend);
        rb_addr_in  <= sbase;
        rb_beats_in <= beats_of(sbytes, szs);
        wb_addr_in  <= dbase;
        wb_beats_in <= beats_of(dbytes, szd);
        // contiguous/fixed sides start the burst engine; gen sides do not
        rb_start    <= (sbytes != 0) & ~gens;
        wb_start    <= ~gend;
        rd_active   <= (sbytes != 0);
        wr_active   <= 1'b1;
        str_out_active <= strm;
        str_in_active  <= strm;
        // gen-mode element walkers (start at the base, template position 0)
        rd_elem_addr <= sbase; wr_elem_addr <= dbase;
        rd_pos <= 5'd0; wr_pos <= 5'd0; gen_rd_busy <= 1'b0;
    endtask

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            ds<=D_DISABLED; ch_enabled<=0;
            fsm_done<=0; fsm_stopped<=0; fsm_disabled<=0; fsm_error<=0;
            fsm_paused<=0; fsm_resumewait<=0; fsm_srctrigwait<=0;
            fsm_destrigwait<=0; fsm_trigoutwait<=0; clr_enablecmd<=0;
            m_axi_arvalid<=0; m_axi_araddr<=0; m_axi_arlen<=0;
            m_axi_arsize<=0; m_axi_arburst<=AXBURST_INCR;
            m_axi_awvalid<=0; m_axi_awaddr<=0; m_axi_awlen<=0;
            m_axi_awsize<=0; m_axi_awburst<=AXBURST_INCR; m_axi_bready<=1;
            rb_start<=0; wb_start<=0;
            rd_active<=0; wr_active<=0; link_rd_active<=0;
            str_out_active<=0; str_in_active<=0; use_stream_q<=0; fill_q<=0;
            fifo_flush<=0; errinfo<=0;
            rd_byte_addr<=0; wr_byte_addr<=0; rd_rem<=0; wr_rem<=0;
            src_line_base<=0; des_line_base<=0; sstride_q<=0; dstride_q<=0;
            line_src_bytes<=0; line_des_bytes<=0; y_rem<=0;
            wrap_q<=0; wrap_last_des_q<=0;
            gen_s_q<=0; gen_d_q<=0; stride_s_q<=0; stride_d_q<=0;
            stsize_s_q<=0; stsize_d_q<=0; stmplt_s_q<=0; stmplt_d_q<=0;
            rd_elem_addr<=0; wr_elem_addr<=0; rd_pos<=0; wr_pos<=0; gen_rd_busy<=0;
            axsize_s_q<=0; axsize_d_q<=0; bbs_q<=1; bbd_q<=1;
            sfixed_q<=0; dfixed_q<=0; fillval_q<=0;
            w_left<=0; awq_cnt<=0; awq_head<=0; awq_tail<=0;
            outstanding_b<=0; rd_out_ch<=0; err_pending<=0;
            paused_req<=0; trigout_started<=0; restart_cnt<=0; restart_inf<=0;
            live_we<=0; iwr_en<=0; iwr_off<=0; iwr_data<=0; iwr_regclear<=0;
            apply_b<=0; apply_idx<=0; apply_first<=0;
            link_fetch_addr<=0; link_word_idx<=0;
            link_words_needed<=0; link_words_got<=0;
            src_trig_take<=0; des_trig_take<=0; trigout_start<=0;
            src_trig_take_last<=0; des_trig_take_last<=0;
            s_axis_in_flush<=0;
            rd_credit<=0; rd_unlimited<=1'b1;
            wr_credit<=0; wr_unlimited<=1'b1;
            empty_q<=0; disable_req<=0;
        end else begin
            fsm_done<=0; fsm_stopped<=0; fsm_disabled<=0; fsm_error<=0;
            clr_enablecmd<=0; rb_start<=0; wb_start<=0;
            live_we<=0; iwr_en<=0; iwr_regclear<=0; m_axi_bready<=1;
            src_trig_take<=0; des_trig_take<=0; trigout_start<=0;
            src_trig_take_last<=0; des_trig_take_last<=0;
            // discard-data hint to the stream-in source while aborting
            s_axis_in_flush <= abort_active & use_stream_q;
            fsm_paused<=0; fsm_resumewait<=0;
            fsm_srctrigwait<=0; fsm_destrigwait<=0; fsm_trigoutwait<=0;

            if (pausecmd)  paused_req <= 1'b1;
            if (resumecmd | restart_req) paused_req <= 1'b0;
            // DISABLECMD is graceful (TRM 6.5.1.1): the current command
            // completes, then the channel disables without linking/restarting.
            if (disablecmd) disable_req <= 1'b1;

            // ---- B responses + outstanding-write accounting (global) ----
            if (b_fire && (m_axi_bresp==RESP_SLVERR || m_axi_bresp==RESP_DECERR)) begin
                err_pending <= 1'b1;
                errinfo[EI_BUSERR]       <= 1'b1;
                errinfo[EI_AXIWRRESPERR] <= 1'b1;
            end
            case ({aw_fire, b_fire})           // one B expected per accepted AW
                2'b10: outstanding_b <= outstanding_b + 1'b1;
                2'b01: if (outstanding_b != 0) outstanding_b <= outstanding_b - 1'b1;
                default: ;
            endcase
            // read error: bus error response / poison flags the channel + cause
            if (r_fire && ~link_rd_active &&
                (m_axi_rresp==RESP_SLVERR || m_axi_rresp==RESP_DECERR || m_axi_rpoison)) begin
                err_pending <= 1'b1;
                errinfo[EI_BUSERR] <= 1'b1;
                if (m_axi_rresp==RESP_SLVERR || m_axi_rresp==RESP_DECERR)
                    errinfo[EI_AXIRDRESPERR] <= 1'b1;
                if (m_axi_rpoison) errinfo[EI_AXIRDPOISERR] <= 1'b1;
            end
            // command-link fetch bus error (also flagged during link reads)
            if (r_fire && link_rd_active &&
                (m_axi_rresp==RESP_SLVERR || m_axi_rresp==RESP_DECERR || m_axi_rpoison)) begin
                err_pending <= 1'b1;
                errinfo[EI_BUSERR] <= 1'b1;
                if (m_axi_rpoison) errinfo[EI_AXIRDPOISERR] <= 1'b1;
                else               errinfo[EI_AXIRDRESPERR] <= 1'b1;
            end
            // ---- stream interface error detection (TRM 5.5 / ERRINFO STR*) ----
            if (use_stream_q) begin
                // invalid tstrb on the stream-in interface (a beat with no bytes)
                if (si_fire && (s_axis_in_tstrb == '0)) begin
                    err_pending<=1'b1; errinfo[EI_STREAMERR]<=1'b1;
                    errinfo[EI_STRINTSTRBERR]<=1'b1;
                end
                // stream-in ended (tlast) before the source finished streaming out
                if (si_fire && s_axis_in_tlast && (rd_rem != 0)) begin
                    err_pending<=1'b1; errinfo[EI_STREAMERR]<=1'b1;
                    errinfo[EI_STRINEARLYTERM]<=1'b1;
                end
            end

            // FIFO push/pop are driven combinationally; clear the flush pulse
            fifo_flush <= 1'b0;

            // ---- read-beat address / remaining ----
            if (push_fire) begin
                rd_rem <= rd_rem - nbytes_s;
                if (gen_s_q) begin
                    // single-element: this transfer done; step to next element
                    gen_rd_busy  <= 1'b0;
                    rd_pos       <= rd_pos_nxt;
                    rd_elem_addr <= rd_elem_addr + stride_s_q;
                end else if (!sfixed_q) begin
                    rd_byte_addr <= rd_byte_addr + nbytes_s;   // contiguous burst
                end
            end
            // ---- stream-out consumes accumulator only (no addr) ----

            // ---- write-beat address / remaining ----
            if (w_fire && !abort_active) begin
                wr_rem <= wr_rem - nbytes_d;
                if (gen_d_q) begin
                    wr_pos       <= wr_pos_nxt;
                    wr_elem_addr <= wr_elem_addr + stride_d_q;
                end else if (!dfixed_q) begin
                    wr_byte_addr <= wr_byte_addr + nbytes_d;
                end
            end

            // ---- channel outstanding-read counter (for clean abort drain) ----
            case ({(ar_fire & ~link_rd_active), (r_fire & m_axi_rlast & ~link_rd_active)})
                2'b10: rd_out_ch <= rd_out_ch + 1'b1;
                2'b01: rd_out_ch <= rd_out_ch - 1'b1;
                default: ;
            endcase

            // ---- trigger flow-control credits (single writer per counter) ----
            // A grant adds SINGLE=1 or BLOCK=TRIGINBLKSIZE+1 transfer credits;
            // each accepted AR/AW consumes its burst length in credits. Issue
            // logic only starts an access whose full length is covered.
            begin : cred_update
                logic [16:0] c, dec; c = rd_credit;
                if (fc_grant_s) c = c + fc_cred_s;
                if (ar_fire && ~link_rd_active && flowctrl_s && ~rd_unlimited) begin
                    dec = {8'd0, ({1'b0, m_axi_arlen} + 9'd1)};
                    c   = (c > dec) ? (c - dec) : 17'd0;
                end
                rd_credit <= c;
            end
            begin : wcred_update
                logic [16:0] c, dec; c = wr_credit;
                if (fc_grant_d) c = c + fc_cred_d;
                if (aw_fire && flowctrl_d && ~wr_unlimited) begin
                    dec = {8'd0, ({1'b0, m_axi_awlen} + 9'd1)};
                    c   = (c > dec) ? (c - dec) : 17'd0;
                end
                wr_credit <= c;
            end

            // ---- write-burst beat-count FIFO: load head / count down / push --
            begin : awq_update
                logic do_load, do_push;
                do_load = (w_left == 9'd0) && (awq_cnt != 0);
                do_push = aw_fire;                     // AW just accepted
                if (w_left == 9'd0) begin
                    if (awq_cnt != 0) begin
                        w_left   <= awq_mem[awq_head];
                        awq_head <= (awq_head + 1) % AWQ_DEPTH;
                    end
                end else if (w_fire) begin
                    w_left <= w_left - 1'b1;
                end
                if (do_push) begin
                    // gen-mode AWs are single-beat; burst-mode uses wb_beats
                    awq_mem[awq_tail] <= gen_d_q ? 9'd1 : wb_beats;
                    awq_tail          <= (awq_tail + 1) % AWQ_DEPTH;
                end
                case ({do_push, do_load})
                    2'b10: awq_cnt <= awq_cnt + 1'b1;
                    2'b01: awq_cnt <= awq_cnt - 1'b1;
                    default: ;
                endcase
            end

            case (ds)
                //----------------------------------------------------------
                D_DISABLED: begin
                    ch_enabled  <= 1'b0;
                    disable_req <= 1'b0;   // DISABLECMD while idle is ignored
                    if (boot_req && !stop_eff) begin
                        ch_enabled<=1'b1; errinfo<=0;
                        link_fetch_addr<={boot_addr_i[ADDR_WIDTH-1:1],1'b0};
                        link_word_idx<=0; link_words_got<=0;
                        ds<=D_LINK_AR;
                    end else if (enablecmd && !clr_enablecmd && !stop_eff) begin
                        // !clr_enablecmd: the auto-clear of ENABLECMD lands one
                        // cycle after D_DONE/D_ERR drops us here, so without this
                        // guard the channel would immediately re-arm and re-run
                        // the (already consumed) command.
                        ch_enabled<=1'b1; errinfo<=0; ds<=D_CFG;
                    end
                end

                //----------------------------------------------------------
                D_CFG: begin : cfg_state
                    // Configuration validation (before any bus transfer, TRM
                    // 5.9.2.2). REGVALERR: illegal field value (TRANSIZE wider
                    // than the bus, trigger selector out of range). CFGCONFLERR:
                    // conflicting settings. XSIZE == 0 / XTYPE = disable are
                    // LEGAL empty commands (TRM 5.2.2), not errors.
                    logic regval_err, cfgconfl_err, emp;
                    logic [31:0] sb, db, ln_des, ln_src;
                    logic [15:0] passes;
                    logic signed [15:0] einc_s, einc_d;            // element increment
                    logic signed [ADDR_WIDTH-1:0] strs, strd;      // byte stride/pos
                    logic gens, gend, sfx, dfx;
                    regval_err   = (src_transize > LOG2BPB[2:0])   // TRANSIZE > bus
                                 | trigcfg_regval_err;             // trig sel range
                    cfgconfl_err = (fill_en & usestream)
                                 | (wrap_en & fill_en)
                                 | ((flowctrl_s | flowctrl_d) & usestream)   // TRM 5.9.2.2
                                 | (flowctrl_s & wrap_en)
                                 | ((flowctrl_s | flowctrl_d) & (ysize > 16'd1));
                    emp = (xtype == 3'b000);                       // empty command
                    sb = src_xsize << src_transize;                // total source bytes
                    db = des_xsize << des_transize;                // total dest bytes
                    // Per-element stride from CH_XADDRINC (TRM 5.2.3): 0 keeps
                    // the address fixed (peripheral FIFO), 1 is contiguous, any
                    // other (incl. negative) selects single-element gen mode.
                    // Templating also forces gen mode (TRM 5.3.3).
                    einc_s = src_xaddrinc;
                    einc_d = des_xaddrinc;
                    sfx    = (einc_s == 16'sd0);
                    dfx    = (einc_d == 16'sd0);
                    strs   = sfx ? '0 : (einc_s <<< src_transize);
                    strd   = dfx ? '0 : (einc_d <<< des_transize);
                    gens   = (srctmpltsize != 0) | (~sfx & (einc_s != 16'sd1));
                    gend   = (destmpltsize != 0) | (~dfx & (einc_d != 16'sd1));
                    if (regval_err || cfgconfl_err ||
                        srctrigin_sel_err || destrigin_sel_err || trigout_sel_err) begin
                        if (regval_err || cfgconfl_err) errinfo[EI_CFGERR] <= 1'b1;
                        if (regval_err)   errinfo[EI_REGVALERR]   <= 1'b1;
                        if (cfgconfl_err) errinfo[EI_CFGCONFLERR] <= 1'b1;
                        // trigger-port selection conflicts (TRM Table 5-8)
                        if (srctrigin_sel_err) errinfo[EI_SRCTRIGINSELERR] <= 1'b1;
                        if (destrigin_sel_err) errinfo[EI_DESTRIGINSELERR] <= 1'b1;
                        if (trigout_sel_err)   errinfo[EI_TRIGOUTSELERR]   <= 1'b1;
                        ds <= D_ERR;
                    end else begin
                        // latch transfer geometry
                        axsize_s_q <= axsz(src_transize);
                        axsize_d_q <= axsz(des_transize);
                        bbs_q      <= 13'd1 << axsz(src_transize);
                        bbd_q      <= 13'd1 << axsz(des_transize);
                        sfixed_q   <= sfx;
                        dfixed_q   <= dfx;
                        use_stream_q <= usestream;
                        fill_q     <= fill_en;
                        fillval_q  <= fillval;
                        restart_cnt <= cmdrestartcnt;
                        restart_inf <= cmdrestartinfen;
                        src_line_base <= srcaddr;
                        des_line_base <= desaddr;
                        rd_byte_addr <= srcaddr;  wr_byte_addr <= desaddr;
                        fifo_flush<=1'b1;
                        w_left<=0; awq_cnt<=0; awq_head<=0; awq_tail<=0;
                        outstanding_b<=0; rd_out_ch<=0; err_pending<=0;
                        empty_q    <= emp;
                        // latch gen-mode (template / strided single-element) config
                        gen_s_q<=gens; gen_d_q<=gend;
                        stride_s_q<=strs; stride_d_q<=strd;
                        stsize_s_q<=srctmpltsize; stsize_d_q<=destmpltsize;
                        stmplt_s_q<=srctmplt; stmplt_d_q<=destmplt;

                        // ---- XTYPE / 2D geometry ----
                        passes = 16'd1; ln_src = sb; ln_des = db; wrap_q <= 1'b0;
                        if (emp) begin
                            // empty command: no data transfers; still honours
                            // triggers / GPO / trigger-out / done (TRM 5.9.2.2)
                            ln_src = 32'd0; ln_des = 32'd0;
                        end else if (ysize > 16'd1) begin
                            // real 2D: per-line copy (existing behaviour)
                            passes = ysize; sstride_q <= src_stride; dstride_q <= des_stride;
                        end else if (wrap_en && (db > sb) && (sb != 0) && !gens && !gend) begin
                            // 1D WRAP (contiguous): loop of source-block copies
                            passes = (db + sb - 1) / sb;            // ceil(db/sb)
                            ln_des = sb;
                            wrap_q <= 1'b1;
                            wrap_last_des_q <= db - (passes - 1)*sb;
                            sstride_q <= '0;                        // re-read source
                            dstride_q <= sb;                        // next dest block
                        end else begin
                            // continue: stop at min(src,des). FILL: read the
                            // SRCXSIZE source bytes normally, but write the full
                            // DESXSIZE destination - the source shortfall
                            // (DESXSIZE-SRCXSIZE) is padded with FILLVAL once the
                            // source data has drained (see w_use_fill below).
                            ln_des = fill_en ? db : ((db < sb) ? db : sb);
                            sstride_q <= src_stride; dstride_q <= des_stride;
                        end
                        y_rem          <= passes;
                        line_src_bytes <= ln_src;
                        line_des_bytes <= ln_des;
                        rd_rem <= ln_src;
                        wr_rem <= ln_des;

                        if (srctrigin_en || destrigin_en) ds <= D_TRIG_WAIT;
                        else if (emp) ds <= D_DRAIN;
                        else begin
                            start_line(srcaddr, desaddr, ln_src, ln_des,
                                       axsz(src_transize), axsz(des_transize),
                                       usestream, fill_en, gens, gend);
                            ds <= D_XFER;
                        end
                    end
                end

                //----------------------------------------------------------
                D_TRIG_WAIT: begin : trig_wait_state
                    logic src_ok, des_ok;
                    logic [1:0]  t_s, t_d;
                    logic [16:0] cr_s, cr_d;
                    logic [31:0] bb_s, bb_d, eff_src, eff_des;
                    fsm_srctrigwait <= srctrigin_en;
                    fsm_destrigwait <= destrigin_en;
                    if (stop_eff) ds <= D_STOPPED;
                    else begin
                        src_ok = ~srctrigin_en | src_trig_pending | swtrigin_src;
                        des_ok = ~destrigin_en | des_trig_pending | swtrigin_des;
                        // request type: HW pending type, else the SW type field
                        t_s  = src_trig_pending ? src_trig_type : swtrigin_srctype;
                        t_d  = des_trig_pending ? des_trig_type : swtrigin_destype;
                        cr_s = t_s[1] ? blkcred_s : 17'd1;      // BLOCK vs SINGLE
                        cr_d = t_d[1] ? blkcred_d : 17'd1;
                        bb_s = {15'd0, cr_s} << axsize_s_q;     // granted bytes
                        bb_d = {15'd0, cr_d} << axsize_d_q;
                        if (src_ok && des_ok) begin
                            // LAST request closes the command after its block
                            // (TRM Table 5-4): truncate to the granted volume.
                            eff_src = line_src_bytes;
                            eff_des = line_des_bytes;
                            if (flowctrl_s & t_s[0] & (eff_src > bb_s)) begin
                                eff_des = (eff_des > (eff_src - bb_s))
                                          ? (eff_des - (eff_src - bb_s)) : 32'd0;
                                eff_src = bb_s;
                            end
                            if (flowctrl_d & t_d[0] & (eff_des > bb_d))
                                eff_des = bb_d;
                            if (srctrigin_en & src_trig_pending) begin
                                src_trig_take <= 1'b1;
                                // LAST OKAY when this grant completes the command
                                // (DMA-driven flow control, TRM Table 5-5)
                                src_trig_take_last <=
                                    flowctrl_s & (t_s[0] | (line_src_bytes <= bb_s));
                            end
                            if (destrigin_en & des_trig_pending) begin
                                des_trig_take <= 1'b1;
                                des_trig_take_last <=
                                    flowctrl_d & (t_d[0] | (line_des_bytes <= bb_d));
                            end
                            // credit seeding: flow-control modes get one block;
                            // command mode (and internal triggers) run unlimited.
                            if (flowctrl_s) begin
                                rd_credit <= cr_s; rd_unlimited <= 1'b0;
                            end else rd_unlimited <= 1'b1;
                            if (flowctrl_d) begin
                                wr_credit <= cr_d; wr_unlimited <= 1'b0;
                            end else wr_unlimited <= 1'b1;
                            line_src_bytes <= eff_src;
                            line_des_bytes <= eff_des;
                            rd_rem <= eff_src;
                            wr_rem <= eff_des;
                            if (empty_q) ds <= D_DRAIN;
                            else begin
                                start_line(src_line_base, des_line_base,
                                           eff_src, eff_des,
                                           axsize_s_q, axsize_d_q,
                                           use_stream_q, fill_q,
                                           gen_s_q, gen_d_q);
                                ds <= D_XFER;
                            end
                        end
                    end
                end

                //----------------------------------------------------------
                D_XFER: begin
                    if (stop_eff) begin
                        rd_active<=0; wr_active<=0;
                        m_axi_arvalid<=0; m_axi_awvalid<=0;
                        ds <= D_STOPPED;
                    end else if (pause_eff) begin
                        m_axi_arvalid <= m_axi_arvalid & ~ar_fire;
                        ds <= D_PAUSED;
                    end else begin
                        if (err_pending) ds <= D_ERR;

                        // mid-transfer flow control: when a block credit is
                        // spent, stall that side and wait for / take a trigger.
                        fsm_srctrigwait <= fc_need;
                        fsm_destrigwait <= fc_need_d;
                        if (fc_take_mid) begin
                            src_trig_take <= 1'b1;
                            src_trig_take_last <=
                                fc_type_s[0] | (rd_rem <= fc_bytes_s);
                        end
                        if (fc_take_mid_d) begin
                            des_trig_take <= 1'b1;
                            des_trig_take_last <=
                                fc_type_d[0] | (wr_rem <= fc_bytes_d);
                        end
                        // LAST request: this is the final block - truncate the
                        // command to the granted volume (TRM Table 5-4).
                        if (fc_grant_s & fc_type_s[0] & (rd_rem > fc_bytes_s)) begin
                            wr_rem <= (wr_rem > (rd_rem - fc_bytes_s))
                                      ? (wr_rem - (rd_rem - fc_bytes_s)) : 32'd0;
                            rd_rem <= fc_bytes_s;
                        end
                        if (fc_grant_d & fc_type_d[0] & (wr_rem > fc_bytes_d))
                            wr_rem <= fc_bytes_d;

                        // AR issue. Contiguous/fixed sides use the burst engine
                        // (multi-outstanding); gen sides (template / strided) issue
                        // one 1-beat access per element, single-outstanding, and
                        // step over template gaps with no transfer.
                        if (!m_axi_arvalid && rd_active) begin
                            if (gen_s_q) begin
                                if (!gen_rd_busy && rd_rem != 0) begin
                                    if (~rd_tmpl_sel) begin             // template gap
                                        rd_pos       <= rd_pos_nxt;     // (free, no credit)
                                        rd_elem_addr <= rd_elem_addr + stride_s_q;
                                    end else if (rd_cred_ok) begin      // transfer w/ credit
                                        m_axi_araddr  <= rd_elem_addr;
                                        m_axi_arlen   <= 8'd0;
                                        m_axi_arsize  <= axsize_s_q;
                                        m_axi_arburst <= sfixed_q ? 2'b00 : 2'b01;
                                        m_axi_arvalid <= 1'b1;
                                        rd_byte_addr  <= rd_elem_addr;  // R-beat lane
                                        gen_rd_busy   <= 1'b1;
                                    end
                                end
                            end else if (rb_valid && rd_rem != 0 && rd_cred_bok) begin
                                m_axi_araddr  <= rb_addr;
                                m_axi_arlen   <= rb_len;
                                m_axi_arsize  <= axsize_s_q;
                                m_axi_arburst <= rb_type;
                                m_axi_arvalid <= 1'b1;
                            end
                        end else if (ar_fire) m_axi_arvalid <= 1'b0;

                        // AW issue. Burst sides pipeline up to AWQ_DEPTH bursts;
                        // gen sides issue one 1-beat AW per element when no write
                        // is in flight (single-outstanding), skipping dest gaps.
                        if (!m_axi_awvalid) begin
                            if (gen_d_q) begin
                                if (awq_cnt == 0 && w_left == 9'd0 && wr_rem != 0) begin
                                    if (wr_tmpl_sel) begin
                                        if (wr_cred_ok) begin
                                            m_axi_awaddr  <= wr_elem_addr;
                                            m_axi_awlen   <= 8'd0;
                                            m_axi_awsize  <= axsize_d_q;
                                            m_axi_awburst <= dfixed_q ? 2'b00 : 2'b01;
                                            m_axi_awvalid <= 1'b1;
                                            wr_byte_addr  <= wr_elem_addr;  // W-beat lane
                                        end
                                    end else begin                      // template gap
                                        wr_pos       <= wr_pos_nxt;
                                        wr_elem_addr <= wr_elem_addr + stride_d_q;
                                    end
                                end
                            end else if (wb_valid && !awq_full && wr_cred_bok) begin
                                m_axi_awaddr  <= wb_addr;
                                m_axi_awlen   <= wb_len;
                                m_axi_awsize  <= axsize_d_q;
                                m_axi_awburst <= wb_type;
                                m_axi_awvalid <= 1'b1;
                            end
                        end else if (aw_fire) begin
                            m_axi_awvalid <= 1'b0;   // outstanding_b counted globally
                        end

                        // live write-back (approximate)
                        live_we        <= 1'b1;
                        live_srcaddr   <= rd_byte_addr;
                        live_desaddr   <= wr_byte_addr;
                        live_src_xsize <= rd_rem >> axsize_s_q;
                        live_des_xsize <= wr_rem >> axsize_d_q;

                        // line completion: all destination bytes written
                        if (wr_rem == 0 || (w_fire && wr_rem == {19'd0,nbytes_d})) begin
                            rd_active<=0; wr_active<=0;
                            // stream-in overrun: writes finished while the stream-in
                            // FIFO still holds (unconsumed) data (TRM ERRINFO).
                            if (use_stream_q && (wf_count > BPB[FCW-1:0])) begin
                                err_pending<=1'b1; errinfo[EI_STREAMERR]<=1'b1;
                                errinfo[EI_STRINOVERRUN]<=1'b1;
                            end
                            if (y_rem > 16'd1) ds <= D_NEXTLINE;
                            else               ds <= D_DRAIN;
                        end
                    end
                end

                //----------------------------------------------------------
                D_PAUSED: begin
                    fsm_paused     <= 1'b1;
                    // RESUMEWAIT: a SW PAUSECMD needs a RESUMECMD to continue
                    fsm_resumewait <= paused_req;
                    m_axi_arvalid  <= m_axi_arvalid & ~ar_fire;
                    m_axi_awvalid  <= m_axi_awvalid & ~aw_fire;
                    if (stop_eff) ds <= D_STOPPED;
                    else if (!pause_eff) ds <= D_XFER;
                end

                //----------------------------------------------------------
                D_NEXTLINE: begin
                    // hold any in-flight VALID until accepted; drain stragglers
                    m_axi_arvalid <= m_axi_arvalid & ~ar_fire;
                    m_axi_awvalid <= m_axi_awvalid & ~aw_fire;
                    // advance to the next 2D line once this line has fully drained
                    if (outstanding_b == 0 && rd_out_ch == 0
                        && w_left == 9'd0 && awq_cnt == 0
                        && !m_axi_arvalid && !m_axi_awvalid) begin
                        if (err_pending) ds <= D_ERR;
                        else begin : nextline
                            // for WRAP, the final pass writes only the remainder
                            logic [31:0] nl_des;
                            nl_des = (wrap_q && (y_rem == 16'd2)) ? wrap_last_des_q
                                                                  : line_des_bytes;
                            y_rem         <= y_rem - 1'b1;
                            src_line_base <= src_line_base + sstride_q;
                            des_line_base <= des_line_base + dstride_q;
                            rd_byte_addr  <= src_line_base + sstride_q;
                            wr_byte_addr  <= des_line_base + dstride_q;
                            rd_rem        <= line_src_bytes;
                            wr_rem        <= nl_des;
                            w_left<=0; awq_cnt<=0; awq_head<=0; awq_tail<=0;
                            fifo_flush<=1'b1;
                            start_line(src_line_base + sstride_q,
                                       des_line_base + dstride_q,
                                       line_src_bytes, nl_des,
                                       axsize_s_q, axsize_d_q, use_stream_q, fill_q,
                                       gen_s_q, gen_d_q);
                            ds <= D_XFER;
                        end
                    end
                end

                //----------------------------------------------------------
                D_DRAIN: begin
                    // no new bursts; hold any in-flight VALID until accepted
                    m_axi_arvalid <= m_axi_arvalid & ~ar_fire;
                    m_axi_awvalid <= m_axi_awvalid & ~aw_fire;
                    if (err_pending) ds <= D_ERR;
                    else if (outstanding_b == 0 && rd_out_ch == 0
                             && w_left == 9'd0 && awq_cnt == 0
                             && !m_axi_arvalid && !m_axi_awvalid)
                        ds <= trigout_en ? D_TRIGOUT : D_DONE;
                end

                //----------------------------------------------------------
                D_TRIGOUT: begin
                    fsm_trigoutwait <= 1'b1;
                    if (!trigout_started) begin
                        trigout_start <= 1'b1; trigout_started <= 1'b1;
                    end else if (trigout_done | swtrigout_ack) begin
                        // completed by the HW handshake or by a SW acknowledge
                        // (CH_CMD.SWTRIGOUTACK, TRM 5.4.5.2)
                        trigout_started <= 1'b0; ds <= D_DONE;
                    end
                end

                //----------------------------------------------------------
                D_DONE: begin : done_state
                    logic restarting;
                    restarting = ~disable_req & (restart_inf | (restart_cnt != 0));
                    // DONETYPE (TRM 6.5.1.4): 000 = STAT_DONE never asserted;
                    // 001 = end of command; 011 = end of each autorestart cycle.
                    fsm_done <= (donetype == 3'b011) ? 1'b1
                              : (donetype == 3'b001) ? ~restarting
                              : 1'b0;
                    if (disable_req) begin
                        // graceful DISABLECMD (TRM 5.6.1): command completed,
                        // skip autorestart / command link and disable.
                        disable_req<=0; clr_enablecmd<=1; fsm_disabled<=1;
                        ds <= D_DISABLED;
                    end else if (restarting) begin
                        if (!restart_inf) restart_cnt <= restart_cnt - 1'b1;
                        ds <= D_RESTART;
                    end else if (linkaddren) begin
                        link_fetch_addr <= {linkaddr[ADDR_WIDTH-1:1],1'b0};
                        link_word_idx<=0; link_words_got<=0;
                        ds <= D_LINK_AR;
                    end else if (donepauseen) begin
                        ds <= D_DONEPAUSE;
                    end else begin
                        clr_enablecmd<=1; ds <= D_DISABLED;
                    end
                end

                //----------------------------------------------------------
                D_RESTART: begin
                    // reload originals per REGRELOADTYPE and restart the command
                    src_line_base <= (regreloadtype==3'b011||regreloadtype==3'b111)?src_orig:src_line_base;
                    des_line_base <= (regreloadtype==3'b101||regreloadtype==3'b111)?des_orig:des_line_base;
                    rd_byte_addr  <= (regreloadtype==3'b011||regreloadtype==3'b111)?src_orig:src_line_base;
                    wr_byte_addr  <= (regreloadtype==3'b101||regreloadtype==3'b111)?des_orig:des_line_base;
                    rd_rem<=line_src_bytes; wr_rem<=line_des_bytes;
                    y_rem<=(ysize==0)?16'd1:ysize;
                    fifo_flush<=1'b1;
                    w_left<=0; awq_cnt<=0; awq_head<=0; awq_tail<=0;
                    outstanding_b<=0; rd_out_ch<=0; err_pending<=0;
                    start_line((regreloadtype==3'b011||regreloadtype==3'b111)?src_orig:src_line_base,
                               (regreloadtype==3'b101||regreloadtype==3'b111)?des_orig:des_line_base,
                               line_src_bytes, line_des_bytes,
                               axsize_s_q, axsize_d_q, use_stream_q, fill_q,
                               gen_s_q, gen_d_q);
                    ds <= D_XFER;
                end

                //----------------------------------------------------------
                D_LINK_AR: begin
                    link_rd_active <= 1'b1;
                    m_axi_arsize  <= LOG2BPB[2:0];
                    m_axi_arburst <= AXBURST_INCR;
                    if (err_pending) begin link_rd_active<=1'b0; ds<=D_ERR; end
                    else if (!m_axi_arvalid) begin
                        m_axi_araddr<=link_fetch_addr; m_axi_arlen<=8'd0; m_axi_arvalid<=1'b1;
                    end else if (ar_fire) begin
                        m_axi_arvalid<=1'b0; ds<=D_LINK_R;
                    end
                end
                D_LINK_R: begin
                    link_rd_active <= 1'b1;
                    if (err_pending) begin link_rd_active<=1'b0; ds<=D_ERR; end
                    else if (r_fire) begin
                        if (link_word_idx==0) begin
                            link_hdr<=m_axi_rdata;
                            link_words_needed<=count_link_words(m_axi_rdata);
                            // an all-zero header is an invalid command-link header
                            if (m_axi_rdata == 32'h0) begin
                                errinfo[EI_CFGERR]     <= 1'b1;
                                errinfo[EI_LINKHDRERR] <= 1'b1;
                                err_pending <= 1'b1;
                                link_rd_active <= 1'b0;
                                ds <= D_ERR;
                            end else if (count_link_words(m_axi_rdata) == 0) begin
                                // header with no data words: nothing to fetch
                                link_rd_active<=1'b0; apply_first<=1'b1; apply_idx<=0;
                                ds <= D_LINK_APPLY;
                            end else ds <= D_LINK_AR;
                        end else begin
                            link_words[link_word_idx-1]<=m_axi_rdata;
                            link_words_got<=link_words_got+1'b1;
                            if (link_words_got+1>=link_words_needed) begin
                                link_rd_active<=1'b0; apply_first<=1'b1; apply_idx<=0;
                                ds<=D_LINK_APPLY;
                            end else ds<=D_LINK_AR;
                        end
                        link_word_idx<=link_word_idx+1'b1;
                        link_fetch_addr<=link_fetch_addr+4;
                    end
                end
                D_LINK_APPLY: begin
                    // Replay the descriptor into the register frame, one register
                    // per cycle, walking the header LSB->MSB (Table 5-12). Every
                    // word-carrying set bit writes its register at the correct
                    // offset — ALL registers (INTREN included), not a subset.
                    if (apply_first) begin
                        apply_first <= 1'b0;
                        apply_b     <= 6'd1;
                        if (link_hdr[LH_REGCLEAR]) iwr_regclear <= 1'b1;  // clear first
                    end else if (apply_b <= 6'd31) begin
                        if (link_hdr[apply_b] && (link_bit_off(apply_b) != 8'hFF)) begin
                            iwr_en    <= 1'b1;
                            iwr_off   <= link_bit_off(apply_b);
                            iwr_data  <= link_words[apply_idx];
                            apply_idx <= apply_idx + 1'b1;
                        end
                        apply_b <= apply_b + 1'b1;
                    end else begin
                        ds <= D_LINK_WAIT;          // last write settles, then re-run CFG
                    end
                end
                D_LINK_WAIT: ds<=D_CFG;

                //----------------------------------------------------------
                D_DONEPAUSE: begin
                    fsm_paused     <= 1'b1;
                    fsm_resumewait <= 1'b1;
                    if (stop_eff) ds<=D_STOPPED;
                    else if (disable_req) begin
                        disable_req<=0; clr_enablecmd<=1; fsm_disabled<=1;
                        ds<=D_DISABLED;
                    end else if (resumecmd | restart_req) begin
                        clr_enablecmd<=1; ds<=D_DISABLED;
                    end
                end

                //----------------------------------------------------------
                // Abort drain (error). Stop pushing new data; hold AR/AW VALID
                // until accepted; let outstanding reads drain and send the W
                // beats of already-accepted AW bursts (WSTRB forced 0) until all
                // B responses return — then report the error. (abort_active is
                // asserted for this state, driving rready / dummy W.)
                D_ERR: begin
                    rd_active<=0; wr_active<=0;
                    m_axi_arvalid <= m_axi_arvalid & ~ar_fire;  // hold until accepted
                    m_axi_awvalid <= m_axi_awvalid & ~aw_fire;
                    if (rd_out_ch==0 && awq_cnt==0 && w_left==9'd0 &&
                        outstanding_b==0 && !m_axi_arvalid && !m_axi_awvalid) begin
                        fsm_error<=1; clr_enablecmd<=1;
                        fifo_flush<=1'b1;
                        ds<=D_DISABLED;
                    end
                end

                //----------------------------------------------------------
                // Abort drain (stop) — same clean drain, reports STOPPED.
                D_STOPPED: begin
                    rd_active<=0; wr_active<=0;
                    m_axi_arvalid <= m_axi_arvalid & ~ar_fire;
                    m_axi_awvalid <= m_axi_awvalid & ~aw_fire;
                    if (rd_out_ch==0 && awq_cnt==0 && w_left==9'd0 &&
                        outstanding_b==0 && !m_axi_arvalid && !m_axi_awvalid) begin
                        fsm_stopped<=1; clr_enablecmd<=1;
                        fifo_flush<=1'b1;
                        ds<=D_DISABLED;
                    end
                end

                default: ds<=D_DISABLED;
            endcase
        end
    end

endmodule

`default_nettype wire
