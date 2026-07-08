//-----------------------------------------------------------------------------
// dma350_pkg.sv
//
// Central package for the Arm CoreLink DMA-350 RTL. Holds the configurable
// build options (the "Configurable options" of the TRM), the per-channel
// DMACH<n> register offsets, command/status bit positions, the command-link
// header bitmap positions (TRM Table 5-12), and shared enums used by the
// channel command engine.
//
// All widths that may legally be zero in the spec (CHID_WIDTH, POIS_WIDTH)
// are wrapped through dma_nz() so generated vectors are never zero-width.
//-----------------------------------------------------------------------------
`ifndef DMA350_PKG_SV
`define DMA350_PKG_SV

package dma350_pkg;

    // ---- helper: clamp a possibly-zero width to a minimum of 1 -------------
    function automatic int dma_nz(input int w);
        dma_nz = (w <= 0) ? 1 : w;
    endfunction

    // =======================================================================
    // DMACH<n> register offsets (byte address inside a channel block).
    // Subset/superset of TRM 6.4.1 sufficient for the modelled features.
    // =======================================================================
    localparam logic [7:0]
        CH_CMD          = 8'h00,
        CH_STATUS       = 8'h04,
        CH_INTREN       = 8'h08,
        CH_CTRL         = 8'h0C,
        CH_SRCADDR      = 8'h10,
        CH_SRCADDRHI    = 8'h14,
        CH_DESADDR      = 8'h18,
        CH_DESADDRHI    = 8'h1C,
        CH_XSIZE        = 8'h20,
        CH_XSIZEHI      = 8'h24,
        CH_SRCTRANSCFG  = 8'h28,
        CH_DESTRANSCFG  = 8'h2C,
        CH_XADDRINC     = 8'h30,
        CH_YADDRSTRIDE  = 8'h34,
        CH_FILLVAL      = 8'h38,
        CH_YSIZE        = 8'h3C,
        CH_TMPLTCFG     = 8'h40,
        CH_SRCTMPLT     = 8'h44,
        CH_DESTMPLT     = 8'h48,
        CH_SRCTRIGINCFG = 8'h4C,
        CH_DESTRIGINCFG = 8'h50,
        CH_TRIGOUTCFG   = 8'h54,
        CH_GPOEN0       = 8'h58,
        CH_GPOVAL0      = 8'h60,   // TRM 0x60 (not 0x5C)
        CH_STREAMINTCFG = 8'h68,   // TRM 0x68 (not 0x60)
        CH_LINKATTR     = 8'h70,
        CH_AUTOCFG      = 8'h74,
        CH_LINKADDR     = 8'h78,
        CH_LINKADDRHI   = 8'h7C,
        CH_GPOREAD0     = 8'h80,   // RO
        CH_WRKREGPTR    = 8'h88,
        CH_WRKREGVAL    = 8'h8C,   // RO
        CH_ERRINFO      = 8'h90,   // RO  (error cause, Table 5-9)
        CH_IIDR         = 8'hC8,   // RO
        CH_AIDR         = 8'hCC,   // RO
        CH_ISSUECAP     = 8'hE8,
        CH_BUILDCFG0    = 8'hF8,   // RO
        CH_BUILDCFG1    = 8'hFC;   // RO

    // =======================================================================
    // Command-link header (Table 5-12): header bit -> DMACH register offset.
    // Returns 8'hFF for bits that carry no data word (REGCLEAR / reserved).
    // =======================================================================
    function automatic logic [7:0] link_bit_off(input int b);
        case (b)
            2:  link_bit_off = CH_INTREN;
            3:  link_bit_off = CH_CTRL;
            4:  link_bit_off = CH_SRCADDR;
            5:  link_bit_off = CH_SRCADDRHI;
            6:  link_bit_off = CH_DESADDR;
            7:  link_bit_off = CH_DESADDRHI;
            8:  link_bit_off = CH_XSIZE;
            9:  link_bit_off = CH_XSIZEHI;
            10: link_bit_off = CH_SRCTRANSCFG;
            11: link_bit_off = CH_DESTRANSCFG;
            12: link_bit_off = CH_XADDRINC;
            13: link_bit_off = CH_YADDRSTRIDE;
            14: link_bit_off = CH_FILLVAL;
            15: link_bit_off = CH_YSIZE;
            16: link_bit_off = CH_TMPLTCFG;
            17: link_bit_off = CH_SRCTMPLT;
            18: link_bit_off = CH_DESTMPLT;
            19: link_bit_off = CH_SRCTRIGINCFG;
            20: link_bit_off = CH_DESTRIGINCFG;
            21: link_bit_off = CH_TRIGOUTCFG;
            22: link_bit_off = CH_GPOEN0;
            24: link_bit_off = CH_GPOVAL0;
            26: link_bit_off = CH_STREAMINTCFG;
            28: link_bit_off = CH_LINKATTR;
            29: link_bit_off = CH_AUTOCFG;
            30: link_bit_off = CH_LINKADDR;
            31: link_bit_off = CH_LINKADDRHI;
            default: link_bit_off = 8'hFF;     // 0=REGCLEAR, 1/23/25/27=reserved
        endcase
    endfunction

    // =======================================================================
    // CH_CMD bit positions (TRM 6.5.1.1; write-1 to request, self-clearing)
    // =======================================================================
    localparam int CMD_ENABLECMD  = 0;
    localparam int CMD_CLEARCMD   = 1;
    localparam int CMD_DISABLECMD = 2;   // graceful: finish current cmd, no link
    localparam int CMD_STOPCMD    = 3;
    localparam int CMD_PAUSECMD   = 4;
    localparam int CMD_RESUMECMD  = 5;
    localparam int CMD_SRCSWTRIGINREQ     = 16;  // [16]    SW source trigger req
    localparam int CMD_SRCSWTRIGINTYPE_LO = 17;  // [18:17] SW source trigger type
    localparam int CMD_DESSWTRIGINREQ     = 20;  // [20]    SW destination trig req
    localparam int CMD_DESSWTRIGINTYPE_LO = 21;  // [22:21] SW destination trig type
    localparam int CMD_SWTRIGOUTACK       = 24;  // [24]    SW trigger-out acknowledge

    // =======================================================================
    // CH_STATUS bit positions (TRM 6.5.1.2): INTR_* [10:0], STAT_* [26:16]
    // =======================================================================
    localparam int ST_INTR_DONE     = 0;
    localparam int ST_INTR_ERR      = 1;
    localparam int ST_INTR_DISABLED = 2;
    localparam int ST_INTR_STOPPED  = 3;
    localparam int ST_INTR_SRCTRIGINWAIT  = 8;
    localparam int ST_INTR_DESTRIGINWAIT  = 9;
    localparam int ST_INTR_TRIGOUTACKWAIT = 10;
    localparam int ST_STAT_DONE     = 16;
    localparam int ST_STAT_ERR      = 17;
    localparam int ST_STAT_STOPPED  = 18;
    localparam int ST_STAT_DISABLED = 19;
    localparam int ST_STAT_PAUSED   = 20;
    localparam int ST_STAT_RESUMEWAIT = 21;
    localparam int ST_STAT_SRCTRIGINWAIT  = 24;  // TRM 6.5.1.2 [24]
    localparam int ST_STAT_DESTRIGINWAIT  = 25;  // TRM 6.5.1.2 [25]
    localparam int ST_STAT_TRIGOUTACKWAIT = 26;  // TRM 6.5.1.2 [26]

    // =======================================================================
    // CH_ERRINFO bit positions.
    // Detail "reason" fields [26:16] are exact per TRM Table 5-9; the high-level
    // type flags [5:0] are a documented low-bit interpretation.
    // =======================================================================
    localparam int EI_BUSERR          = 0;   // type flags
    localparam int EI_CFGERR          = 1;
    localparam int EI_SRCTRIGINSELERR = 2;
    localparam int EI_DESTRIGINSELERR = 3;
    localparam int EI_TRIGOUTSELERR   = 4;
    localparam int EI_STREAMERR       = 5;
    localparam int EI_AXIRDRESPERR    = 16;  // reason fields (Table 5-9)
    localparam int EI_AXIWRRESPERR    = 17;
    localparam int EI_AXIRDPOISERR    = 18;
    localparam int EI_STRINTSTRBERR   = 19;
    localparam int EI_STRINOVERRUN    = 20;
    localparam int EI_STRINEARLYTERM  = 21;
    localparam int EI_LINKHDRERR      = 24;
    localparam int EI_REGVALERR       = 25;
    localparam int EI_CFGCONFLERR     = 26;

    // =======================================================================
    // CH_INTREN bit positions (TRM 6.5.1.3)
    // =======================================================================
    localparam int IE_DONE     = 0;
    localparam int IE_ERR      = 1;
    localparam int IE_DISABLED = 2;
    localparam int IE_STOPPED  = 3;
    localparam int IE_SRCTRIGINWAIT  = 8;
    localparam int IE_DESTRIGINWAIT  = 9;
    localparam int IE_TRIGOUTACKWAIT = 10;

    // =======================================================================
    // CH_CTRL bit positions (TRM 6.5.1.4)
    // =======================================================================
    //  [2:0]   TRANSIZE      log2(transfer-unit bytes)
    //  [7:4]   CHPRIO        channel priority (passed to AxQOS)
    //  [11:9]  XTYPE         transfer type (0=disable,1=continue,2=wrap,3=fill)
    //  [14:12] YTYPE         2D transfer type
    //  [20:18] REGRELOADTYPE autorestart reload selection
    //  [23:21] DONETYPE      000=no done flag, 001=end of command,
    //                        011=end of autorestart cycle
    //  [24]    DONEPAUSEEN   pause when STAT_DONE asserts
    //  [25]    USESRCTRIGIN  [26] USEDESTRIGIN  [27] USETRIGOUT  [28] USEGPO
    //  [29]    USESTREAM     route data through stream port
    localparam int CTRL_DONEPAUSEEN = 24;
    localparam int CTRL_USESTREAM   = 29;

    // =======================================================================
    // Command-link header bitmap (TRM Table 5-12) - which words follow header.
    // Bit index == register field index in the descriptor.
    // =======================================================================
    localparam int LH_REGCLEAR    = 0;
    localparam int LH_INTREN      = 2;
    localparam int LH_CTRL        = 3;
    localparam int LH_SRCADDR     = 4;
    localparam int LH_SRCADDRHI   = 5;
    localparam int LH_DESADDR     = 6;
    localparam int LH_DESADDRHI   = 7;
    localparam int LH_XSIZE       = 8;
    localparam int LH_XSIZEHI     = 9;
    localparam int LH_SRCTRANSCFG = 10;
    localparam int LH_DESTRANSCFG = 11;
    localparam int LH_AUTOCFG     = 29;
    localparam int LH_LINKADDR    = 30;

    // =======================================================================
    // Trigger handshake encodings (TRM Tables 5-4 / 5-5)
    //   reqtype: bit1 = BLOCK (else SINGLE), bit0 = LAST
    // =======================================================================
    localparam logic [1:0] TRIGREQ_SINGLE      = 2'b00;
    localparam logic [1:0] TRIGREQ_LAST_SINGLE = 2'b01;
    localparam logic [1:0] TRIGREQ_BLOCK       = 2'b10;
    localparam logic [1:0] TRIGREQ_LAST_BLOCK  = 2'b11;
    localparam logic [1:0] TRIGACK_OKAY        = 2'b00;
    localparam logic [1:0] TRIGACK_DENY        = 2'b01;
    localparam logic [1:0] TRIGACK_LASTOKAY    = 2'b10;

    // CH_*TRIGINCFG.*TRIGINMODE (TRM 6.5.1.20/21)
    localparam logic [1:0] TRIGMODE_CMD       = 2'b00;  // command trigger
    localparam logic [1:0] TRIGMODE_FLOW_DMA  = 2'b10;  // DMA-driven flow control
    localparam logic [1:0] TRIGMODE_FLOW_PERI = 2'b11;  // peripheral-driven flow ctl

    // CH_*TRIGINCFG.*TRIGINTYPE / CH_TRIGOUTCFG.TRIGOUTTYPE (TRM 6.5.1.20-22)
    localparam logic [1:0] TRIGTYPE_SW        = 2'b00;  // software-only trigger
    localparam logic [1:0] TRIGTYPE_HW        = 2'b10;  // external HW trigger port
    localparam logic [1:0] TRIGTYPE_INTERNAL  = 2'b11;  // channel-to-channel

    // =======================================================================
    // AXI burst/resp encodings
    // =======================================================================
    localparam logic [1:0] AXBURST_INCR = 2'b01;
    localparam logic [1:0] RESP_OKAY    = 2'b00;
    localparam logic [1:0] RESP_EXOKAY  = 2'b01;
    localparam logic [1:0] RESP_SLVERR  = 2'b10;
    localparam logic [1:0] RESP_DECERR  = 2'b11;

endpackage

`endif
