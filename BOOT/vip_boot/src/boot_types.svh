//------------------------------------------------------------------------------
// boot_types.svh
//
// Enumerations and helpers for the DMA-350 boot configuration interface.
// Encodings mirror the LINKMEMATTRHI/LINKMEMATTRLO (CH_LINKATTR) and
// LINKSHAREATTR fields, which boot_memattr/boot_shareattr reuse
// (TRM 102482, sections 4.9.1 and 6.5.1.26).
//------------------------------------------------------------------------------
`ifndef BOOT_TYPES_SVH
`define BOOT_TYPES_SVH

// boot_shareattr[1:0] - Shareability attribute (== LINKSHAREATTR)
typedef enum logic [1:0] {
  BOOT_SHARE_NON       = 2'b00, // Non-shareable
  BOOT_SHARE_RESERVED  = 2'b01, // Reserved (illegal)
  BOOT_SHARE_OUTER     = 2'b10, // Outer shareable
  BOOT_SHARE_INNER     = 2'b11  // Inner shareable
} boot_shareattr_e;

// boot_memattr[7:4] - MEMATTRHI nibble (== LINKMEMATTRHI)
//   0000        => Device memory
//   non-zero    => Normal memory, outer cache attributes
typedef enum logic [3:0] {
  BOOT_MEMHI_DEVICE              = 4'b0000,
  BOOT_MEMHI_NORM_OWA_WT_T       = 4'b0001,
  BOOT_MEMHI_NORM_ORA_WT_T       = 4'b0010,
  BOOT_MEMHI_NORM_ORWA_WT_T      = 4'b0011,
  BOOT_MEMHI_NORM_ONC            = 4'b0100,
  BOOT_MEMHI_NORM_OWA_WB_T       = 4'b0101,
  BOOT_MEMHI_NORM_ORA_WB_T       = 4'b0110,
  BOOT_MEMHI_NORM_ORWA_WB_T      = 4'b0111,
  BOOT_MEMHI_NORM_OWT_NT         = 4'b1000,
  BOOT_MEMHI_NORM_OWA_WT_NT      = 4'b1001,
  BOOT_MEMHI_NORM_ORA_WT_NT      = 4'b1010,
  BOOT_MEMHI_NORM_ORWA_WT_NT     = 4'b1011,
  BOOT_MEMHI_NORM_OWB_NT         = 4'b1100,
  BOOT_MEMHI_NORM_OWA_WB_NT      = 4'b1101,
  BOOT_MEMHI_NORM_ORA_WB_NT      = 4'b1110,
  BOOT_MEMHI_NORM_ORWA_WB_NT     = 4'b1111
} boot_memattr_hi_e;

// boot_memattr[3:0] - MEMATTRLO nibble when MEMATTRHI == Device (0000)
//   only 0000/0100/1000/1100 are legal; others are UNPREDICTABLE.
typedef enum logic [3:0] {
  BOOT_DEV_nGnRnE = 4'b0000,
  BOOT_DEV_nGnRE  = 4'b0100,
  BOOT_DEV_nGRE   = 4'b1000,
  BOOT_DEV_GRE    = 4'b1100
} boot_device_lo_e;

`endif // BOOT_TYPES_SVH
