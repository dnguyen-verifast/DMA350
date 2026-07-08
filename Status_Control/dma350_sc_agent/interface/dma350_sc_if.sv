//==============================================================================
// dma350_sc_if.sv
//------------------------------------------------------------------------------
// Interface for the DMA-350 "Control and status interface" (TRM Table A-10).
//
// Scope (all four functional groups of section 4.8):
//   G1  General purpose outputs .......... gpo_ch_<N>            (4.8.1)
//   G2  Stop control ..................... allch_stop_*          (4.8.2)
//   G2b Pause control .................... allch_pause_*         (4.8.2)
//   G3  Cross Trigger Interface (CTI) .... halt_req/restart_req/halted (4.8.3)
//   G4  Per-channel status ............... ch_enabled/err/...    (4.8.4)
//
// Existence of some signals is build-dependent:
//   - the *_sec req/ack pairs and ch_nonsec exist only when SECEXT_PRESENT=1
//   - gpo_ch_<N> exists only when CH_GPO_MASK[N]=1  (and GPO_WIDTH>0)
//
// To keep one vif type usable across every build, the SIGNALS are declared at
// the spec maxima (8 channels, 32-bit GPO) and the AGENT decides, from its
// config object, which bits/ports are real for the current build. Loops in the
// driver/monitor are bounded by cfg.num_channels / cfg.gpo_width, and the
// *_sec / ch_nonsec / gpo logic is gated by cfg.secext_present / cfg.ch_gpo_mask.
//
// Direction convention is from the DUT (DMAC) point of view, matching Table A-10.
// The testbench therefore DRIVES the DUT inputs and MONITORS the DUT outputs:
//   TB drives   : allch_stop_req_*, allch_pause_req_*, halt_req, restart_req
//   TB monitors : allch_stop_ack_*, allch_pause_ack_*, halted, gpo_ch_*, ch_*
//==============================================================================
`ifndef DMA350_SC_IF__SV
`define DMA350_SC_IF__SV

// Spec maxima – used to size the physical wires so a single vif type works
// for any legal build configuration.
`ifndef DMA350_SC_MAX_CHANNELS
  `define DMA350_SC_MAX_CHANNELS 8      // NUM_CHANNELS : 1..8   (3.4)
`endif
`ifndef DMA350_SC_MAX_GPO_WIDTH
  `define DMA350_SC_MAX_GPO_WIDTH 32    // GPO_WIDTH    : 0..32  (3.4)
`endif

interface dma350_sc_if (input logic clk, input logic resetn);

  // --- sized locals -------------------------------------------------------
  localparam int MAXCH  = `DMA350_SC_MAX_CHANNELS;
  localparam int GPOW   = `DMA350_SC_MAX_GPO_WIDTH;

  //========================================================================
  // Group 1 : General Purpose Outputs (4.8.1)  -- DUT output, per channel
  //   Present per channel when CH_GPO_MASK[N]=1. Value is stable while the
  //   channel is active; holds last value when the channel stops driving it.
  //========================================================================
  logic [GPOW-1:0] gpo_ch [MAXCH];

  //========================================================================
  // Group 2 : Stop control (4.8.2)  -- 4-phase handshake
  //   req : DUT input  (TB drives)
  //   ack : DUT output (TB monitors)
  //   _sec pair only exists when SECEXT_PRESENT=1
  //========================================================================
  logic allch_stop_req_nonsec;   // DUT in
  logic allch_stop_ack_nonsec;   // DUT out
  logic allch_stop_req_sec;      // DUT in  (SECEXT_PRESENT=1)
  logic allch_stop_ack_sec;      // DUT out (SECEXT_PRESENT=1)

  //========================================================================
  // Group 2b : Pause control (4.8.2)  -- 4-phase handshake
  //========================================================================
  logic allch_pause_req_nonsec;  // DUT in
  logic allch_pause_ack_nonsec;  // DUT out
  logic allch_pause_req_sec;     // DUT in  (SECEXT_PRESENT=1)
  logic allch_pause_ack_sec;     // DUT out (SECEXT_PRESENT=1)

  //========================================================================
  // Group 3 : Cross Trigger Interface / CTI (4.8.3)
  //   halt_req    : DUT input,  LEVEL  (TB drives, hold high to keep halted)
  //   restart_req : DUT input,  PULSE  (TB drives a 1-cycle pulse to resume)
  //   halted      : DUT output, PULSE  (TB monitors a 1-cycle pulse)
  //========================================================================
  logic halt_req;      // DUT in  (level)
  logic restart_req;   // DUT in  (pulse)
  logic halted;        // DUT out (pulse)

  //========================================================================
  // Group 4 : Per-channel status (4.8.4)  -- DUT outputs, [NUM_CHANNELS-1:0]
  //   When SECEXT_PRESENT=1 the enabled/err/stopped/paused/priv signals must
  //   be interpreted together with ch_nonsec to know the channel's domain.
  //   ch_nonsec does not exist when SECEXT_PRESENT=0.
  //========================================================================
  logic [MAXCH-1:0] ch_enabled;
  logic [MAXCH-1:0] ch_err;
  logic [MAXCH-1:0] ch_stopped;
  logic [MAXCH-1:0] ch_paused;
  logic [MAXCH-1:0] ch_priv;
  logic [MAXCH-1:0] ch_nonsec;   // SECEXT_PRESENT=1 only

  // ---- clocking blocks ---------------------------------------------------
  // Driver drives DUT inputs; samples nothing critical here.
  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output allch_stop_req_nonsec, allch_stop_req_sec;
    output allch_pause_req_nonsec, allch_pause_req_sec;
    output halt_req, restart_req;
    input  allch_stop_ack_nonsec, allch_stop_ack_sec;
    input  allch_pause_ack_nonsec, allch_pause_ack_sec;
    input  halted;
  endclocking

  // Monitor samples every DUT output. NOTE: gpo_ch is an unpacked array and is
  // deliberately NOT placed in the clocking block (some simulators reject
  // unpacked arrays there). It is read directly through the MON modport; it is
  // spec-guaranteed stable while a channel is active, so a non-sampled read is
  // safe.
  clocking mon_cb @(posedge clk);
    default input #1step;
    input allch_stop_req_nonsec, allch_stop_req_sec;
    input allch_stop_ack_nonsec, allch_stop_ack_sec;
    input allch_pause_req_nonsec, allch_pause_req_sec;
    input allch_pause_ack_nonsec, allch_pause_ack_sec;
    input halt_req, restart_req, halted;
    input ch_enabled, ch_err, ch_stopped, ch_paused, ch_priv, ch_nonsec;
  endclocking

  modport DRV (clocking drv_cb, input clk, input resetn);
  modport MON (clocking mon_cb, input clk, input resetn, input gpo_ch);

  // ---- reset-time initialisation of TB-driven inputs ---------------------
  // Keeps the DUT inputs at their benign deasserted level out of reset so a
  // build that leaves some of them unconnected never floats.
  initial begin
    allch_stop_req_nonsec  = 1'b0;
    allch_stop_req_sec     = 1'b0;
    allch_pause_req_nonsec = 1'b0;
    allch_pause_req_sec    = 1'b0;
    halt_req               = 1'b0;
    restart_req            = 1'b0;
  end

endinterface : dma350_sc_if

`endif // DMA350_SC_IF__SV
