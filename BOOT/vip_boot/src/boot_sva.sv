//------------------------------------------------------------------------------
// boot_sva.sv
//
// Concurrent SystemVerilog assertions for the boot configuration interface.
// Intended to be bound onto boot_if (or directly onto the DUT boot pins):
//
//   bind boot_if boot_sva #(.ADDR_WIDTH(ADDR_WIDTH), .SECEXT_PRESENT(0))
//     u_boot_sva (.clk(clk), .resetn(resetn),
//                 .boot_en(boot_en), .boot_addr(boot_addr),
//                 .boot_memattr(boot_memattr), .boot_shareattr(boot_shareattr),
//                 .boot_fetch_started(boot_fetch_started));
//
// The stability window assertion requires boot_fetch_started to mark the start
// of the boot command fetch (e.g. first channel-0 command-link AXI read).
//------------------------------------------------------------------------------
`ifndef BOOT_SVA_SV
`define BOOT_SVA_SV

module boot_sva #(
  parameter int  ADDR_WIDTH        = 32,
  parameter bit  SECEXT_PRESENT    = 0,
  parameter bit  CHECK_STABILITY   = 1,
  parameter logic [63:0] SECURE_BASE  = 64'h0,
  parameter logic [63:0] SECURE_LIMIT = 64'hFFFF_FFFF_FFFF_FFFF
) (
  input logic                  clk,
  input logic                  resetn,
  input logic                  boot_en,
  input logic [ADDR_WIDTH-1:2] boot_addr,
  input logic [7:0]            boot_memattr,
  input logic [1:0]            boot_shareattr,
  input logic                  boot_fetch_started
);

  // Capture the configuration at the deasserting edge of resetn.
  logic                  boot_en_q;
  logic [ADDR_WIDTH-1:2] boot_addr_q;
  logic [7:0]            boot_memattr_q;
  logic [1:0]            boot_shareattr_q;
  logic                  in_window;

  // Explicit reset-edge detection (avoids $rose() in procedural code).
  logic                  resetn_q;
  wire                   reset_release = resetn & ~resetn_q;

  always_ff @(posedge clk) begin
    resetn_q <= resetn;
    if (!resetn) begin
      in_window <= 1'b0;
    end
    else begin
      // Rising edge of resetn -> latch and open the stability window.
      if (reset_release) begin
        boot_en_q        <= boot_en;
        boot_addr_q      <= boot_addr;
        boot_memattr_q   <= boot_memattr;
        boot_shareattr_q <= boot_shareattr;
        in_window        <= boot_en; // only meaningful when booting
      end
      else if (boot_fetch_started) begin
        in_window <= 1'b0;
      end
    end
  end

  // --------------------------------------------------------------------------
  // A_SHARE_LEGAL: boot_shareattr must never be the Reserved encoding 2'b01.
  // --------------------------------------------------------------------------
  a_share_legal : assert property (
    @(posedge clk) disable iff (!resetn)
    boot_shareattr != 2'b01
  ) else $error("boot_shareattr == 2'b01 is Reserved/illegal");

  // --------------------------------------------------------------------------
  // A_DEVICE_LO_LEGAL: Device-type boot_memattr (hi==0000) must use a legal
  // *LO encoding (nGnRnE/nGnRE/nGRE/GRE); others are UNPREDICTABLE.
  // --------------------------------------------------------------------------
  a_device_lo_legal : assert property (
    @(posedge clk) disable iff (!resetn)
    (boot_memattr[7:4] == 4'b0000) |->
      (boot_memattr[3:0] inside {4'b0000, 4'b0100, 4'b1000, 4'b1100})
  ) else $error("Device boot_memattr LO=0x%01h is UNPREDICTABLE", boot_memattr[3:0]);

  // --------------------------------------------------------------------------
  // A_NORMAL_LO_LEGAL: Normal-memory boot_memattr (hi!=0000) LO must not be
  // 0000 (Reserved).
  // --------------------------------------------------------------------------
  a_normal_lo_legal : assert property (
    @(posedge clk) disable iff (!resetn)
    (boot_memattr[7:4] != 4'b0000) |-> (boot_memattr[3:0] != 4'b0000)
  ) else $error("Normal-memory boot_memattr LO=0000 is Reserved");

  // --------------------------------------------------------------------------
  // A_STABLE_WINDOW: while booting, boot_* must be stable from reset
  // deassertion until boot_fetch_started.
  // --------------------------------------------------------------------------
  if (CHECK_STABILITY) begin : g_stable
    a_en_stable : assert property (
      @(posedge clk) disable iff (!resetn)
      (in_window && !boot_fetch_started) |=> (boot_en == boot_en_q)
    ) else $error("boot_en changed before boot fetch started (TRM 4.9.1)");

    a_addr_stable : assert property (
      @(posedge clk) disable iff (!resetn)
      (in_window && !boot_fetch_started) |=> (boot_addr == boot_addr_q)
    ) else $error("boot_addr changed before boot fetch started (TRM 4.9.1)");

    a_memattr_stable : assert property (
      @(posedge clk) disable iff (!resetn)
      (in_window && !boot_fetch_started) |=> (boot_memattr == boot_memattr_q)
    ) else $error("boot_memattr changed before boot fetch started (TRM 4.9.1)");

    a_shareattr_stable : assert property (
      @(posedge clk) disable iff (!resetn)
      (in_window && !boot_fetch_started) |=> (boot_shareattr == boot_shareattr_q)
    ) else $error("boot_shareattr changed before boot fetch started (TRM 4.9.1)");
  end

  // --------------------------------------------------------------------------
  // A_SECURE_ADDR: with Security Extension present, an enabled boot must point
  // into the Secure region (channel 0 boots Secure).
  // --------------------------------------------------------------------------
  if (SECEXT_PRESENT) begin : g_secure
    a_secure_addr : assert property (
      @(posedge clk) disable iff (!resetn)
      $rose(resetn) && boot_en |->
        (({boot_addr, 2'b00} >= SECURE_BASE) &&
         ({boot_addr, 2'b00} <  SECURE_LIMIT))
    ) else $error("SECEXT boot_addr 0x%0h outside Secure region",
                  {boot_addr, 2'b00});
  end

endmodule : boot_sva

`endif // BOOT_SVA_SV
