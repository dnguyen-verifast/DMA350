//==============================================================================
// lpi_qchannel_if.sv
// Q-Channel interface (ARM IHI 0068D, Chapter 2).
//
// Signal directions follow Figure 2-1:
//   Controller -> Device : QREQn
//   Device -> Controller : QACCEPTn, QDENY, QACTIVE
//
// Both QREQn/QACCEPTn carry the active-LOW 'n' naming, but this VIP treats the
// raw bit values exactly as tabulated in Table 2-1 (Q-Channel interface states).
//==============================================================================
interface lpi_qchannel_if (input logic clk, input logic resetn);

  // Controller-driven
  logic qreqn;
  // Device-driven
  logic qacceptn;
  logic qdeny;
  logic qactive;

  // ---- Controller modport (drives QREQn, samples acks) ----
  clocking ctrl_cb @(posedge clk);
    output qreqn;
    input  qacceptn, qdeny, qactive;
  endclocking

  // ---- Device modport (drives acks/active, samples QREQn) ----
  clocking dev_cb @(posedge clk);
    output qacceptn, qdeny, qactive;
    input  qreqn;
  endclocking

  // ---- Passive monitor clocking ----
  clocking mon_cb @(posedge clk);
    input qreqn, qacceptn, qdeny, qactive;
  endclocking

  modport CTRL (clocking ctrl_cb, input clk, input resetn);
  modport DEV  (clocking dev_cb,  input clk, input resetn);
  modport MON  (clocking mon_cb,  input clk, input resetn);

endinterface : lpi_qchannel_if
