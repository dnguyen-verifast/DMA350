//==============================================================================
// lpi_pchannel_if.sv
// P-Channel interface (ARM IHI 0068D, Chapter 3).
//
// Signal directions follow Figure 3-1:
//   Controller -> Device : PSTATE[M-1:0], PREQ
//   Device -> Controller : PACCEPT, PDENY, PACTIVE[N-1:0]
//==============================================================================
`include "lpi_defs.svh"

interface lpi_pchannel_if (input logic clk, input logic resetn);

  // Controller-driven
  logic [`LPI_PSTATE_W-1:0]  pstate;
  logic                      preq;
  // Device-driven
  logic                      paccept;
  logic                      pdeny;
  logic [`LPI_PACTIVE_W-1:0] pactive;

  clocking ctrl_cb @(posedge clk);
    output pstate, preq;
    input  paccept, pdeny, pactive;
  endclocking

  clocking dev_cb @(posedge clk);
    output paccept, pdeny, pactive;
    input  pstate, preq;
  endclocking

  clocking mon_cb @(posedge clk);
    input pstate, preq, paccept, pdeny, pactive;
  endclocking

  modport CTRL (clocking ctrl_cb, input clk, input resetn);
  modport DEV  (clocking dev_cb,  input clk, input resetn);
  modport MON  (clocking mon_cb,  input clk, input resetn);

endinterface : lpi_pchannel_if
