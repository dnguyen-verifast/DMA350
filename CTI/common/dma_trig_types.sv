//============================================================================
// dma_trig_types.sv
// Enumerations and typedefs shared across the trigger VIP.
// Ref: TRM Table 5-4 (request types), Table 5-5 (acknowledge types).
//============================================================================
`ifndef DMA_TRIG_TYPES_SV
`define DMA_TRIG_TYPES_SV

// Trigger-input usage mode (TRM 5.4.1). Selects how the DMAC is expected to
// acknowledge, which the scoreboard uses to check ack_type semantics:
//   CMD  : command-mode trigger  -> ACK = "accepted, command may start".
//          Only OKAY/LAST_OKAY are legal; DENY must never occur.
//   FLOW : flow-control trigger   -> ACK = "block done after last response".
//          OKAY per block, LAST_OKAY on the final (short) block; DENY allowed
//          (DMAC denies a SINGLE while accumulating a BLOCK / SW auto-clear).
typedef enum {
  DMA_TRIG_MODE_CMD,
  DMA_TRIG_MODE_FLOW
} dma_trig_mode_e;

// reqtype[1:0] encodings (TRM Table 5-4).
typedef enum logic [1:0] {
  DMA_TRIG_SINGLE      = 2'b00,
  DMA_TRIG_LAST_SINGLE = 2'b01,
  DMA_TRIG_BLOCK       = 2'b10,
  DMA_TRIG_LAST_BLOCK  = 2'b11
} dma_trig_reqtype_e;

// acktype[1:0] encodings (TRM Table 5-5).
typedef enum logic [1:0] {
  DMA_TRIG_OKAY      = 2'b00,
  DMA_TRIG_DENY      = 2'b01,
  DMA_TRIG_LAST_OKAY = 2'b10,
  DMA_TRIG_ACK_RSVD  = 2'b11
} dma_trig_acktype_e;

`endif // DMA_TRIG_TYPES_SV
