//------------------------------------------------------------------------------
// boot_dut_stub.sv
//
// Lightweight behavioral model of the DMAC autoboot front-end, used only to
// exercise the VIP. It mimics the TRM 5.7.3 "Autoboot process":
//   * after reset is released (and conceptually after LPI channels are active),
//     if boot_en was latched HIGH it begins fetching the boot command and
//     pulses boot_fetch_started, which closes the VIP stability window.
//
// This is NOT the real DMAC; replace with the actual RTL in integration.
//------------------------------------------------------------------------------
`ifndef BOOT_DUT_STUB_SV
`define BOOT_DUT_STUB_SV

module boot_dut_stub #(
  parameter int ADDR_WIDTH       = 32,
  // cycles after reset release before the boot fetch begins
  parameter int FETCH_LATENCY    = 5
) (
  input  logic                  clk,
  input  logic                  resetn,
  input  logic                  boot_en,
  input  logic [ADDR_WIDTH-1:2] boot_addr,
  input  logic [7:0]            boot_memattr,
  input  logic [1:0]            boot_shareattr,
  output logic                  boot_fetch_started
);

  logic                  boot_en_l;
  logic [ADDR_WIDTH-1:2] boot_addr_l;
  int                    cnt;

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      boot_fetch_started <= 1'b0;
      cnt                <= 0;
      // Latch the configuration at reset (sampled at release).
      boot_en_l          <= boot_en;
      boot_addr_l        <= boot_addr;
    end
    else begin
      boot_en_l   <= boot_en_l;   // hold latched value
      boot_addr_l <= boot_addr_l;
      boot_fetch_started <= 1'b0;  // default: single-cycle pulse
      if (boot_en_l) begin
        if (cnt < FETCH_LATENCY) begin
          cnt <= cnt + 1;
        end
        else if (cnt == FETCH_LATENCY) begin
          boot_fetch_started <= 1'b1;  // pulse: boot command fetch starts
          cnt                <= cnt + 1;
          // synthesisable model would issue the AXI command-link read here
          // using boot_addr_l / boot_memattr / boot_shareattr.
          $display("[%0t] boot_dut_stub: fetching boot command @0x%0h",
                   $time, {boot_addr_l, 2'b00});
        end
      end
    end
  end

endmodule : boot_dut_stub

`endif // BOOT_DUT_STUB_SV
