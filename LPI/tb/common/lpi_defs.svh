//==============================================================================
// lpi_defs.svh
// Global defines for the AMBA Low Power Interface (LPI) VIP-to-VIP testbench.
// Based on: ARM IHI 0068D - AMBA Low Power Interface Specification.
//==============================================================================
`ifndef LPI_DEFS_SVH
`define LPI_DEFS_SVH

// P-Channel signal widths (IMPLEMENTATION DEFINED in the spec, fixed here).
// This VIP models a device with 4 power states:
//   ON, Warm reset mode, Full retention mode, OFF
//   -> M = 2 (4 PSTATE encodings)
//   -> N = 4 (one PACTIVE bit per state, MSB = highest/ON, LSB = OFF)
`ifndef LPI_PSTATE_W
  `define LPI_PSTATE_W 2      // PSTATE[M-1:0], M = 2
`endif
`ifndef LPI_PACTIVE_W
  `define LPI_PACTIVE_W 4     // PACTIVE[N-1:0], N = 4
`endif

`endif // LPI_DEFS_SVH
