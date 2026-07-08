//-----------------------------------------------------------------------------
// dma350_ch_regs.sv
//
// DMACH<n> register frame for one DMA-350 channel (TRM 6.4.1). The frame is
// addressed by the parent via a per-channel select plus an 8-bit offset; the
// parent forms PREADY/PSLVERR and muxes PRDATA across channels.
//
// Coverage (full register set; some 2D/template/security fields are stored and
// read back for completeness while the datapath models the 1D path):
//   CMD, STATUS, INTREN, CTRL, SRC/DESADDR(HI), XSIZE(HI), SRC/DESTRANSCFG,
//   XADDRINC, YADDRSTRIDE, FILLVAL, YSIZE, TMPLTCFG, SRC/DESTMPLT,
//   SRC/DESTRIGINCFG, TRIGOUTCFG, GPOEN0/GPOVAL0, STREAMINTCFG, LINKATTR,
//   AUTOCFG, LINKADDR(HI).
//
// CH_CMD supports ENABLE/CLEAR/DISABLE/STOP/PAUSE/RESUME and SW trigger
// requests. CH_STATUS carries DONE/ERR/STOPPED/DISABLED/PAUSED/RESUMEWAIT and
// the trigger-wait flags. Config registers are SW read-only while ch_enabled;
// the command engine updates live counters and bulk-loads linked descriptors.
//-----------------------------------------------------------------------------
`default_nettype none

module dma350_ch_regs import dma350_pkg::*; #(
    parameter int ADDR_WIDTH    = 32,
    parameter int GPO_WIDTH     = 4,
    parameter int SECEXT_PRESENT = 1,
    parameter bit BOOT_SECURE   = 1'b0   // reset security context of this channel
)(
    input  wire                       pclk,
    input  wire                       presetn,

    // ---- APB4 (pre-decoded by parent) ----
    input  wire                       sel,        // this channel block selected
    input  wire                       penable,
    input  wire                       pwrite,
    input  wire [7:0]                 paddr,      // offset within the block
    input  wire [31:0]                pwdata,
    input  wire [3:0]                 pstrb,
    output reg  [31:0]                prdata,
    output reg                        pslverr,

    // ---- command requests to the engine ----
    output reg                        enablecmd,
    output reg                        stopcmd,
    output reg                        pausecmd,
    output reg                        resumecmd,
    output reg                        disablecmd,
    output reg                        clearcmd,
    output reg                        swtrigin_src,
    output reg                        swtrigin_des,
    output reg  [1:0]                 swtrigin_srctype,  // CMD[18:17]
    output reg  [1:0]                 swtrigin_destype,  // CMD[22:21]
    output reg                        swtrigout_ack,     // CMD[24] pulse

    // ---- status from the engine ----
    input  wire                       ch_enabled,
    input  wire                       fsm_done,
    input  wire                       fsm_stopped,
    input  wire                       fsm_disabled,
    input  wire                       fsm_error,
    input  wire                       fsm_paused,        // level
    input  wire                       fsm_resumewait,    // level
    input  wire                       fsm_srctrigwait,   // level
    input  wire                       fsm_destrigwait,   // level
    input  wire                       fsm_trigoutwait,   // level
    input  wire                       clr_enablecmd,

    // ---- live configuration to the engine ----
    output reg  [ADDR_WIDTH-1:0]      srcaddr,
    output reg  [ADDR_WIDTH-1:0]      desaddr,
    output wire [31:0]                src_xsize,     // {XSIZEHI, XSIZE} source items
    output wire [31:0]                des_xsize,     // destination items
    output reg  [2:0]                 src_transize,  // log2 source unit bytes
    output reg  [2:0]                 des_transize,  // log2 destination unit bytes
    output reg  signed [15:0]         src_xaddrinc,  // source element increment (signed)
    output reg  signed [15:0]         des_xaddrinc,  // destination element increment
    output reg  [2:0]                 xtype,         // CH_CTRL.XTYPE (1D wrap type)
    output reg  [2:0]                 ytype,         // CH_CTRL.YTYPE (2D wrap type)
    output reg                        wrap_en,       // XTYPE == wrap
    output reg                        fill_en,       // XTYPE == fill
    output wire [15:0]                ysize,         // 2D line count
    output wire [ADDR_WIDTH-1:0]      src_stride,    // 2D source line stride (bytes)
    output wire [ADDR_WIDTH-1:0]      des_stride,    // 2D destination line stride
    output wire [31:0]                fillval,
    output wire [31:0]                srctmplt,      // source template bit-mask
    output wire [31:0]                destmplt,      // destination template bit-mask
    output reg  [4:0]                 srctmpltsize,  // SRCTMPLTSIZE (0 = disabled)
    output reg  [4:0]                 destmpltsize,  // DESTMPLTSIZE (0 = disabled)
    output reg  [3:0]                 chprio,        // CH_CTRL.CHPRIO[7:4]
    output reg                        usestream,
    output reg                        donepauseen,
    output reg  [2:0]                 donetype,      // CH_CTRL.DONETYPE[23:21]
    output reg  [2:0]                 regreloadtype,
    output reg  [15:0]                cmdrestartcnt,
    output reg                        cmdrestartinfen,
    output reg  [ADDR_WIDTH-1:0]      linkaddr,
    output reg                        linkaddren,

    // attributes derived from SRC/DESTRANSCFG (TRM 6.5.1.11/12 field layout)
    output reg  [3:0]                 src_cache,     // MEMATTRHI (outer) -> AxCACHE
    output reg  [2:0]                 src_prot,      // {1'b0, NONSECATTR, PRIVATTR}
    output reg  [1:0]                 src_domain,    // SHAREATTR
    output reg  [3:0]                 src_inner,     // MEMATTRLO (inner)
    output reg  [3:0]                 src_maxburstlen, // SRCMAXBURSTLEN [19:16]
    output reg  [3:0]                 des_cache,
    output reg  [2:0]                 des_prot,
    output reg  [1:0]                 des_domain,
    output reg  [3:0]                 des_inner,
    output reg  [3:0]                 des_maxburstlen, // DESMAXBURSTLEN [19:16]

    // trigger configuration (TRM 6.5.1.20-22 field layout: SEL=[7:0],
    // TYPE=[9:8] 00=SW/10=HW/11=internal, MODE=[11:10], BLKSIZE=[23:16])
    output reg                        srctrigin_en,
    output reg  [7:0]                 srctrigin_sel,
    output reg                        srctrigin_hw,        // TYPE == HW
    output reg                        srctrigin_internal,  // TYPE == internal
    output reg  [1:0]                 srctrigin_mode,      // internal forces CMD
    output reg  [7:0]                 srctrigin_blksize,   // TRIGINBLKSIZE (+1)
    output reg                        destrigin_en,
    output reg  [7:0]                 destrigin_sel,
    output reg                        destrigin_hw,
    output reg                        destrigin_internal,
    output reg  [1:0]                 destrigin_mode,
    output reg  [7:0]                 destrigin_blksize,
    output reg                        trigout_en,
    output reg  [7:0]                 trigout_sel,
    output reg                        trigout_hw,
    output reg                        trigout_internal,

    // GPO output value (holds its last driven value while disabled, TRM 4.8.1)
    output wire [GPO_WIDTH-1:0]       gpo_out,

    // ---- engine write-back of live counters ----
    input  wire                       live_we,
    input  wire [ADDR_WIDTH-1:0]      live_srcaddr,
    input  wire [ADDR_WIDTH-1:0]      live_desaddr,
    input  wire [31:0]                live_src_xsize,
    input  wire [31:0]                live_des_xsize,

    // ---- engine internal register write (command linking / boot) ----
    // The command engine replays a fetched descriptor into the register frame
    // one register at a time through this port (bypasses the SW config lock).
    input  wire                       iwr_en,        // internal write strobe
    input  wire [7:0]                 iwr_off,       // DMACH register offset
    input  wire [31:0]                iwr_data,
    input  wire                       iwr_regclear,  // REGCLEAR: reset config regs

    // ---- shadow originals for autorestart reload ----
    output wire [ADDR_WIDTH-1:0]      src_orig_o,
    output wire [ADDR_WIDTH-1:0]      des_orig_o,
    output wire [31:0]                srcx_orig_o,
    output wire [31:0]                desx_orig_o,

    // ---- error cause (CH_ERRINFO readback, from the engine) ----
    input  wire [31:0]                errinfo,

    // ---- interrupt ----
    output wire                       irq
);
    // -------- raw register storage --------
    reg [31:0] ctrl_q, intren_q;
    reg [31:0] srctranscfg_q, destranscfg_q;
    reg [31:0] srcaddrhi_q, desaddrhi_q, linkaddrhi_q, xsizehi_q;
    reg [31:0] xaddrinc_q, yaddrstride_q, fillval_q, ysize_q;
    reg [31:0] tmpltcfg_q, srctmplt_q, destmplt_q;
    reg [31:0] srctrigincfg_q, destrigincfg_q, trigoutcfg_q;
    reg [31:0] gpoen0_q, gpoval0_q, streamintcfg_q, linkattr_q;
    reg [31:0] issuecap_q, wrkregptr_q;

    // -------- implementation-defined ID / build configuration (RO) --------
    localparam [31:0] CH_IIDR_VAL     = 32'h3A00_043B;  // PRODUCTID=0x3A0, IMPL=0x43B (Arm)
    localparam [31:0] CH_AIDR_VAL     = 32'h0000_0010;  // architecture 1.0
    localparam [31:0] CH_BUILDCFG0_VAL= 32'h0000_0000;  // per-channel build (impl)
    localparam [31:0] CH_BUILDCFG1_VAL= 32'h0000_0000;

    // -------- status sticky bits --------
    reg stat_done, stat_err, stat_stopped, stat_disabled, stat_paused;

    // -------- GPO output hold register (keeps last driven value) --------
    reg [GPO_WIDTH-1:0] gpo_out_q;
    assign gpo_out = gpo_out_q;

    // -------- 16-bit XSIZE low halves (extended by XSIZEHI) --------
    reg [15:0] srcxs_lo, desxs_lo;

    // -------- autorestart shadow originals --------
    reg [ADDR_WIDTH-1:0] src_orig, des_orig;
    reg [31:0]           srcx_orig, desx_orig;

    localparam [31:0] CTRL_RST     = 32'h00200200; // TRANSIZE=word, XTYPE=cont
    localparam [31:0] TRANSCFG_RST = 32'h000F0400;

    // composed 32-bit transfer sizes + read-back of 2D / fill / template
    assign src_xsize  = {xsizehi_q[15:0],  srcxs_lo};
    assign des_xsize  = {xsizehi_q[31:16], desxs_lo};
    assign ysize      = ysize_q[15:0];
    // 2D line strides come from CH_YADDRSTRIDE (signed), NOT XADDRINC.
    assign src_stride = {{(ADDR_WIDTH-16){yaddrstride_q[15]}},  yaddrstride_q[15:0]};
    assign des_stride = {{(ADDR_WIDTH-16){yaddrstride_q[31]}},  yaddrstride_q[31:16]};
    assign fillval    = fillval_q;
    assign srctmplt   = srctmplt_q;
    assign destmplt   = destmplt_q;

    // -------- decode exposed control/attribute fields (TRM 6.5.1 CH_CTRL) -----
    always_comb begin
        // TRANSIZE drives AxSIZE; CH_CTRL[2:0] is the transfer-unit size.
        src_transize  = ctrl_q[2:0];
        des_transize  = ctrl_q[2:0];
        chprio        = ctrl_q[7:4];           // CHPRIO is [7:4]
        xtype         = ctrl_q[11:9];          // 000=disable 001=cont 010=wrap 011=fill
        ytype         = ctrl_q[14:12];
        wrap_en       = (ctrl_q[11:9] == 3'b010);
        fill_en       = (ctrl_q[11:9] == 3'b011);
        regreloadtype = ctrl_q[20:18];
        donetype      = ctrl_q[23:21];         // DONETYPE (TRM 6.5.1.4)
        donepauseen   = ctrl_q[24];
        usestream     = ctrl_q[29];

        // per-element address increment (signed) from CH_XADDRINC. Per TRM 5.2.3
        // an increment of 0 means the address does not advance (FIFO / FIXED).
        src_xaddrinc  = xaddrinc_q[15:0];
        des_xaddrinc  = xaddrinc_q[31:16];

        // template length fields (0 = templating disabled)
        srctmpltsize  = tmpltcfg_q[4:0];
        destmpltsize  = tmpltcfg_q[20:16];

        // AXI attributes per the TRM 6.5.1.11/12 TRANSCFG layout:
        //   [3:0] MEMATTRLO (inner) -> arinner/awinner
        //   [7:4] MEMATTRHI (outer) -> AxCACHE (behavioral map)
        //   [9:8] SHAREATTR         -> AxDOMAIN
        //   [10]  NONSECATTR, [11] PRIVATTR -> AxPROT[1]/[0] (combined with the
        //         channel security/privilege context in the top level)
        //   [19:16] MAXBURSTLEN     -> burst-length limit (beats = value + 1)
        src_cache       = srctranscfg_q[7:4];
        src_inner       = srctranscfg_q[3:0];
        src_domain      = srctranscfg_q[9:8];
        src_prot        = {1'b0, srctranscfg_q[10], srctranscfg_q[11]};
        src_maxburstlen = srctranscfg_q[19:16];
        des_cache       = destranscfg_q[7:4];
        des_inner       = destranscfg_q[3:0];
        des_domain      = destranscfg_q[9:8];
        des_prot        = {1'b0, destranscfg_q[10], destranscfg_q[11]};
        des_maxburstlen = destranscfg_q[19:16];

        // trigger ENABLE from CH_CTRL (USE*); SEL/TYPE/MODE/BLKSIZE from the
        // trigger config registers (TRM 6.5.1.20-22 layout). Internal triggers
        // are always command mode (TRM 5.4.4).
        srctrigin_en       = ctrl_q[25];       // USESRCTRIGIN
        srctrigin_sel      = srctrigincfg_q[7:0];
        srctrigin_hw       = (srctrigincfg_q[9:8] == TRIGTYPE_HW);
        srctrigin_internal = (srctrigincfg_q[9:8] == TRIGTYPE_INTERNAL);
        srctrigin_mode     = (srctrigincfg_q[9:8] == TRIGTYPE_INTERNAL)
                             ? TRIGMODE_CMD : srctrigincfg_q[11:10];
        srctrigin_blksize  = srctrigincfg_q[23:16];  // block = BLKSIZE + 1
        destrigin_en       = ctrl_q[26];       // USEDESTRIGIN
        destrigin_sel      = destrigincfg_q[7:0];
        destrigin_hw       = (destrigincfg_q[9:8] == TRIGTYPE_HW);
        destrigin_internal = (destrigincfg_q[9:8] == TRIGTYPE_INTERNAL);
        destrigin_mode     = (destrigincfg_q[9:8] == TRIGTYPE_INTERNAL)
                             ? TRIGMODE_CMD : destrigincfg_q[11:10];
        destrigin_blksize  = destrigincfg_q[23:16];
        trigout_en         = ctrl_q[27];       // USETRIGOUT
        trigout_sel        = {2'b00, trigoutcfg_q[5:0]};   // TRIGOUTSEL [5:0]
        trigout_hw         = (trigoutcfg_q[9:8] == TRIGTYPE_HW);
        trigout_internal   = (trigoutcfg_q[9:8] == TRIGTYPE_INTERNAL);
    end

    wire wr = sel & penable & pwrite;
    wire cfg_wr_ok = ~ch_enabled;          // SW config locked while running

    // byte-strobe note: per Appendix A pstrb is all-or-nothing (4'h0 / 4'hF).
    wire strb_bad = wr & (pstrb != 4'h0) & (pstrb != 4'hF);

    // Shared config-register write: the command engine's internal write (link)
    // takes priority; APB config writes are gated by the lock except GPOVAL0 /
    // WRKREGPTR which are live. CMD(0x00)/STATUS(0x04) are handled separately.
    wire        apb_cfg_ok = cfg_wr_ok | (paddr==CH_GPOVAL0) | (paddr==CH_WRKREGPTR);
    wire        apb_cfg_wr = wr & ~strb_bad & apb_cfg_ok & (paddr >= CH_INTREN);
    wire        cwr_en   = iwr_en | apb_cfg_wr;
    wire [7:0]  cwr_off  = iwr_en ? iwr_off  : paddr;
    wire [31:0] cwr_data = iwr_en ? iwr_data : pwdata;

    always_ff @(posedge pclk) begin
        if (!presetn) begin
            enablecmd<=0; stopcmd<=0; pausecmd<=0; resumecmd<=0;
            disablecmd<=0; clearcmd<=0; swtrigin_src<=0; swtrigin_des<=0;
            swtrigin_srctype<=2'b00; swtrigin_destype<=2'b00; swtrigout_ack<=0;
            gpo_out_q<='0;
            ctrl_q<=CTRL_RST; intren_q<=0;
            srctranscfg_q<=TRANSCFG_RST; destranscfg_q<=TRANSCFG_RST;
            srcaddr<=0; desaddr<=0; srcaddrhi_q<=0; desaddrhi_q<=0;
            srcxs_lo<=0; desxs_lo<=0; xsizehi_q<=0;
            xaddrinc_q<=0; yaddrstride_q<=0; fillval_q<=0; ysize_q<=0;
            tmpltcfg_q<=0; srctmplt_q<=0; destmplt_q<=0;
            srctrigincfg_q<=0; destrigincfg_q<=0; trigoutcfg_q<=0;
            gpoen0_q<=0; gpoval0_q<=0; streamintcfg_q<=0; linkattr_q<=0;
            issuecap_q<=0; wrkregptr_q<=0;
            cmdrestartcnt<=0; cmdrestartinfen<=0;
            linkaddr<=0; linkaddren<=0; linkaddrhi_q<=0;
            stat_done<=0; stat_err<=0; stat_stopped<=0; stat_disabled<=0;
            stat_paused<=0;
            src_orig<=0; des_orig<=0; srcx_orig<=0; desx_orig<=0;
            pslverr<=0;
        end else begin
            pslverr      <= strb_bad;
            // self-clearing command pulses
            stopcmd<=0; pausecmd<=0; resumecmd<=0;
            disablecmd<=0; clearcmd<=0; swtrigin_src<=0; swtrigin_des<=0;
            swtrigout_ack<=0;

            // GPO: while a command with USEGPO runs, enabled lanes drive
            // GPOVAL0; disabled lanes and idle channels keep the last value.
            if (ch_enabled && ctrl_q[28])
                gpo_out_q <= (gpo_out_q & ~gpoen0_q[GPO_WIDTH-1:0])
                           | (gpoval0_q[GPO_WIDTH-1:0] & gpoen0_q[GPO_WIDTH-1:0]);

            // ---- status updates from the engine ----
            if (fsm_done)     stat_done     <= 1'b1;
            if (fsm_error)    stat_err      <= 1'b1;
            if (fsm_stopped)  stat_stopped  <= 1'b1;
            if (fsm_disabled) stat_disabled <= 1'b1;
            if (fsm_paused)   stat_paused   <= 1'b1;
            if (clr_enablecmd) enablecmd    <= 1'b0;

            // ---- live counter write-back ----
            if (live_we) begin
                srcaddr   <= live_srcaddr;
                desaddr   <= live_desaddr;
                srcxs_lo  <= live_src_xsize[15:0];
                desxs_lo  <= live_des_xsize[15:0];
                xsizehi_q <= {live_des_xsize[31:16], live_src_xsize[31:16]};
            end

            // ---- command-link REGCLEAR (reset config before applying words) ----
            if (iwr_regclear) begin
                ctrl_q<=CTRL_RST; intren_q<=0;
                srctranscfg_q<=TRANSCFG_RST; destranscfg_q<=TRANSCFG_RST;
                xaddrinc_q<=0; yaddrstride_q<=0; fillval_q<=0; ysize_q<=0;
                tmpltcfg_q<=0; srctmplt_q<=0; destmplt_q<=0;
                srctrigincfg_q<=0; destrigincfg_q<=0; trigoutcfg_q<=0;
                gpoen0_q<=0; gpoval0_q<=0; streamintcfg_q<=0; linkattr_q<=0;
                linkaddr<=0; linkaddren<=0; cmdrestartcnt<=0; cmdrestartinfen<=0;
            end

            // ---- APB CMD / STATUS (command + W1C status, APB only) ----
            if (wr && !strb_bad && paddr==CH_CMD) begin
                if (pwdata[CMD_ENABLECMD] && !ch_enabled) begin
                    enablecmd <= 1'b1;
                    src_orig<=srcaddr; des_orig<=desaddr;
                    srcx_orig<=src_xsize; desx_orig<=des_xsize;
                    stat_done<=0; stat_err<=0; stat_stopped<=0;
                    stat_disabled<=0; stat_paused<=0;
                end
                if (pwdata[CMD_CLEARCMD])   clearcmd     <= 1'b1;
                if (pwdata[CMD_DISABLECMD]) disablecmd   <= 1'b1;
                if (pwdata[CMD_STOPCMD])    stopcmd      <= 1'b1;
                if (pwdata[CMD_PAUSECMD])   pausecmd     <= 1'b1;
                if (pwdata[CMD_RESUMECMD])  resumecmd    <= 1'b1;
                // SW trigger interface (TRM 5.4.5 / 6.5.1.1 bit positions)
                if (pwdata[CMD_SRCSWTRIGINREQ]) swtrigin_src <= 1'b1;
                if (pwdata[CMD_DESSWTRIGINREQ]) swtrigin_des <= 1'b1;
                if (pwdata[CMD_SWTRIGOUTACK])   swtrigout_ack <= 1'b1;
                swtrigin_srctype <= pwdata[CMD_SRCSWTRIGINTYPE_LO +: 2];
                swtrigin_destype <= pwdata[CMD_DESSWTRIGINTYPE_LO +: 2];
            end
            if (wr && !strb_bad && paddr==CH_STATUS) begin   // W1C
                if (pwdata[ST_STAT_DONE])     stat_done     <= 1'b0;
                if (pwdata[ST_STAT_ERR])      stat_err      <= 1'b0;
                if (pwdata[ST_STAT_STOPPED])  stat_stopped  <= 1'b0;
                if (pwdata[ST_STAT_DISABLED]) stat_disabled <= 1'b0;
                if (pwdata[ST_STAT_PAUSED])   stat_paused   <= 1'b0;
            end

            // ---- config-register writes (APB or command-link internal) ----
            // Drives ALL configuration registers, so a linked descriptor that
            // sets any header bit updates the correct register (INTREN included).
            if (cwr_en) begin
                case (cwr_off)
                    CH_INTREN:      intren_q <= cwr_data;
                    CH_CTRL:        ctrl_q   <= cwr_data;
                    CH_SRCADDR:     srcaddr  <= cwr_data[ADDR_WIDTH-1:0];
                    CH_SRCADDRHI:   srcaddrhi_q <= cwr_data;
                    CH_DESADDR:     desaddr  <= cwr_data[ADDR_WIDTH-1:0];
                    CH_DESADDRHI:   desaddrhi_q <= cwr_data;
                    CH_XSIZE: begin        // SRCXSIZE [15:0], DESXSIZE [31:16]
                        srcxs_lo <= cwr_data[15:0];
                        desxs_lo <= cwr_data[31:16];
                    end
                    CH_XSIZEHI:     xsizehi_q <= cwr_data;
                    CH_SRCTRANSCFG: srctranscfg_q <= cwr_data;
                    CH_DESTRANSCFG: destranscfg_q <= cwr_data;
                    CH_XADDRINC:    xaddrinc_q <= cwr_data;
                    CH_YADDRSTRIDE: yaddrstride_q <= cwr_data;
                    CH_FILLVAL:     fillval_q <= cwr_data;
                    CH_YSIZE:       ysize_q <= cwr_data;
                    CH_TMPLTCFG:    tmpltcfg_q <= cwr_data;
                    CH_SRCTMPLT:    srctmplt_q <= cwr_data;
                    CH_DESTMPLT:    destmplt_q <= cwr_data;
                    CH_SRCTRIGINCFG:srctrigincfg_q <= cwr_data;
                    CH_DESTRIGINCFG:destrigincfg_q <= cwr_data;
                    CH_TRIGOUTCFG:  trigoutcfg_q <= cwr_data;
                    CH_GPOEN0:      gpoen0_q <= cwr_data;
                    CH_GPOVAL0:     gpoval0_q <= cwr_data;
                    CH_STREAMINTCFG:streamintcfg_q <= cwr_data;
                    CH_LINKATTR:    linkattr_q <= cwr_data;
                    CH_AUTOCFG: begin
                        cmdrestartcnt   <= cwr_data[15:0];
                        cmdrestartinfen <= cwr_data[16];
                    end
                    CH_LINKADDR: begin
                        linkaddr   <= cwr_data[ADDR_WIDTH-1:0];
                        linkaddren <= cwr_data[0];
                    end
                    CH_LINKADDRHI: linkaddrhi_q <= cwr_data;
                    CH_ISSUECAP:   issuecap_q <= cwr_data;
                    CH_WRKREGPTR:  wrkregptr_q <= cwr_data;
                    default: ;
                endcase
            end
        end
    end

    // ---- APB read mux ----
    always_comb begin
        prdata = 32'h0;
        case (paddr)
            CH_CMD:        prdata = {7'b0, swtrigout_ack, 1'b0,
                                     swtrigin_destype, swtrigin_des, 1'b0,
                                     swtrigin_srctype, swtrigin_src,
                                     10'b0, resumecmd, pausecmd, stopcmd,
                                     disablecmd, clearcmd, enablecmd};
            CH_STATUS:     prdata = build_status();
            CH_INTREN:     prdata = intren_q;
            CH_CTRL:       prdata = ctrl_q;
            CH_SRCADDR:    prdata = srcaddr;
            CH_SRCADDRHI:  prdata = srcaddrhi_q;
            CH_DESADDR:    prdata = desaddr;
            CH_DESADDRHI:  prdata = desaddrhi_q;
            CH_XSIZE:      prdata = {desxs_lo, srcxs_lo};
            CH_XSIZEHI:    prdata = xsizehi_q;
            CH_SRCTRANSCFG:prdata = srctranscfg_q;
            CH_DESTRANSCFG:prdata = destranscfg_q;
            CH_XADDRINC:   prdata = xaddrinc_q;
            CH_YADDRSTRIDE:prdata = yaddrstride_q;
            CH_FILLVAL:    prdata = fillval_q;
            CH_YSIZE:      prdata = ysize_q;
            CH_TMPLTCFG:   prdata = tmpltcfg_q;
            CH_SRCTMPLT:   prdata = srctmplt_q;
            CH_DESTMPLT:   prdata = destmplt_q;
            CH_SRCTRIGINCFG:prdata = srctrigincfg_q;
            CH_DESTRIGINCFG:prdata = destrigincfg_q;
            CH_TRIGOUTCFG: prdata = trigoutcfg_q;
            CH_GPOEN0:     prdata = gpoen0_q;
            CH_GPOVAL0:    prdata = gpoval0_q;
            CH_STREAMINTCFG:prdata = streamintcfg_q;
            CH_LINKATTR:   prdata = linkattr_q;
            CH_AUTOCFG:    prdata = {15'b0, cmdrestartinfen, cmdrestartcnt};
            CH_LINKADDR:   prdata = linkaddr;
            CH_LINKADDRHI: prdata = linkaddrhi_q;
            // ---- read-only ID / build / status registers ----
            CH_GPOREAD0:   prdata = {{(32-GPO_WIDTH){1'b0}}, gpo_out_q};
            CH_WRKREGPTR:  prdata = wrkregptr_q;
            CH_WRKREGVAL:  prdata = 32'h0;            // working-reg view (not modelled)
            CH_ERRINFO:    prdata = errinfo;
            CH_ISSUECAP:   prdata = issuecap_q;
            CH_IIDR:       prdata = CH_IIDR_VAL;
            CH_AIDR:       prdata = CH_AIDR_VAL;
            CH_BUILDCFG0:  prdata = CH_BUILDCFG0_VAL;
            CH_BUILDCFG1:  prdata = CH_BUILDCFG1_VAL;
            default:       prdata = 32'h0;
        endcase
    end

    function automatic [31:0] build_status();
        logic [31:0] s;
        s = 32'h0;
        s[ST_STAT_DONE]          = stat_done;
        s[ST_STAT_ERR]           = stat_err;
        s[ST_STAT_STOPPED]       = stat_stopped;
        s[ST_STAT_DISABLED]      = stat_disabled;
        s[ST_STAT_PAUSED]        = stat_paused;
        s[ST_STAT_RESUMEWAIT]    = fsm_resumewait;
        s[ST_STAT_SRCTRIGINWAIT] = fsm_srctrigwait;
        s[ST_STAT_DESTRIGINWAIT] = fsm_destrigwait;
        s[ST_STAT_TRIGOUTACKWAIT]= fsm_trigoutwait;
        // INTR_* flags (TRM 6.5.1.2): STAT source gated by its INTREN enable
        s[ST_INTR_DONE]          = stat_done       & intren_q[IE_DONE];
        s[ST_INTR_ERR]           = stat_err        & intren_q[IE_ERR];
        s[ST_INTR_DISABLED]      = stat_disabled   & intren_q[IE_DISABLED];
        s[ST_INTR_STOPPED]       = stat_stopped    & intren_q[IE_STOPPED];
        s[ST_INTR_SRCTRIGINWAIT] = fsm_srctrigwait & intren_q[IE_SRCTRIGINWAIT];
        s[ST_INTR_DESTRIGINWAIT] = fsm_destrigwait & intren_q[IE_DESTRIGINWAIT];
        s[ST_INTR_TRIGOUTACKWAIT]= fsm_trigoutwait & intren_q[IE_TRIGOUTACKWAIT];
        return s;
    endfunction

    assign src_orig_o  = src_orig;
    assign des_orig_o  = des_orig;
    assign srcx_orig_o = srcx_orig;
    assign desx_orig_o = desx_orig;

    assign irq = (stat_done       & intren_q[IE_DONE])
               | (stat_err        & intren_q[IE_ERR])
               | (stat_stopped    & intren_q[IE_STOPPED])
               | (stat_disabled   & intren_q[IE_DISABLED])
               | (fsm_srctrigwait & intren_q[IE_SRCTRIGINWAIT])
               | (fsm_destrigwait & intren_q[IE_DESTRIGINWAIT])
               | (fsm_trigoutwait & intren_q[IE_TRIGOUTACKWAIT]);

endmodule

`default_nettype wire
