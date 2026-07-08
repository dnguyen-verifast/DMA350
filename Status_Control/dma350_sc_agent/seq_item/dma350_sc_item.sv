//==============================================================================
// dma350_sc_item.sv
//------------------------------------------------------------------------------
// Transaction for the status/control agent.
//
// One item = one stimulus action on the control interface, plus (for monitor
// items) a snapshot of the observed status so the scoreboard can use ch_* as
// the golden per-channel reference.
//==============================================================================
`ifndef DMA350_SC_ITEM__SV
`define DMA350_SC_ITEM__SV

// Which control action the driver should perform.
typedef enum {
  SC_NOP,          // idle for `duration` cycles (also used for monitor items)
  SC_STOP,         // 4-phase all-channel STOP  handshake  (4.8.2)
  SC_PAUSE,        // 4-phase all-channel PAUSE handshake  (4.8.2)
  SC_RESUME,       // deassert a held pause request        (4.8.2)
  SC_HALT,         // CTI: assert halt_req (level)         (4.8.3)
  SC_RESTART,      // CTI: pulse restart_req               (4.8.3)
  SC_GPO_SAMPLE    // request monitor to snapshot GPO/status (no drive)
} dma350_sc_op_e;

// Which security domain the stop/pause request targets.
//   NONSEC -> drive *_nonsec req
//   SEC    -> drive *_sec    req  (illegal unless secext_present)
//   BOTH   -> drive both req lines (interleaving corner case)
typedef enum { SC_NONSEC, SC_SEC, SC_BOTH } dma350_sc_dom_e;

class dma350_sc_item extends uvm_sequence_item;

  // ---- stimulus fields ---------------------------------------------------
  rand dma350_sc_op_e  op       = SC_NOP;
  rand dma350_sc_dom_e domain   = SC_NONSEC;

  // For SC_STOP/SC_PAUSE: hold the request asserted after the ack handshake
  // for `hold_cycles` before releasing. For SC_HALT: how long to keep the
  // level asserted before an (optional) auto restart. 0 = release right away.
  rand int unsigned    hold_cycles  = 0;

  // Gap (idle cycles) after the action completes, before the next item.
  rand int unsigned    duration     = 0;

  // For SC_HALT: automatically issue a restart pulse after hold_cycles.
  rand bit             auto_restart = 1'b0;

  // ---- observed / expected fields (filled by monitor) --------------------
  // Snapshots of the DUT status outputs at the moment the item was produced.
  bit [`DMA350_SC_MAX_CHANNELS-1:0] ch_enabled;
  bit [`DMA350_SC_MAX_CHANNELS-1:0] ch_err;
  bit [`DMA350_SC_MAX_CHANNELS-1:0] ch_stopped;
  bit [`DMA350_SC_MAX_CHANNELS-1:0] ch_paused;
  bit [`DMA350_SC_MAX_CHANNELS-1:0] ch_priv;
  bit [`DMA350_SC_MAX_CHANNELS-1:0] ch_nonsec;
  bit [`DMA350_SC_MAX_GPO_WIDTH-1:0] gpo_ch [`DMA350_SC_MAX_CHANNELS];

  // Handshake completion flags recorded by driver/monitor.
  bit ack_nonsec_seen;
  bit ack_sec_seen;
  bit halted_seen;

  `uvm_object_utils_begin(dma350_sc_item)
    `uvm_field_enum(dma350_sc_op_e,  op,       UVM_ALL_ON)
    `uvm_field_enum(dma350_sc_dom_e, domain,   UVM_ALL_ON)
    `uvm_field_int (hold_cycles,   UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (duration,      UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (auto_restart,  UVM_ALL_ON)
    `uvm_field_int (ch_enabled,    UVM_ALL_ON | UVM_BIN)
    `uvm_field_int (ch_err,        UVM_ALL_ON | UVM_BIN)
    `uvm_field_int (ch_stopped,    UVM_ALL_ON | UVM_BIN)
    `uvm_field_int (ch_paused,     UVM_ALL_ON | UVM_BIN)
    `uvm_field_int (ch_priv,       UVM_ALL_ON | UVM_BIN)
    `uvm_field_int (ch_nonsec,     UVM_ALL_ON | UVM_BIN)
    `uvm_field_int (ack_nonsec_seen, UVM_ALL_ON)
    `uvm_field_int (ack_sec_seen,    UVM_ALL_ON)
    `uvm_field_int (halted_seen,     UVM_ALL_ON)
  `uvm_object_utils_end

  // Keep gaps small by default so random tests stay snappy, but SOFT so a
  // sequence that passes an explicit hold/duration (e.g. a long stop hold) wins
  // instead of failing randomize.
  constraint c_reasonable {
    soft hold_cycles inside {[0:64]};
    soft duration    inside {[0:64]};
  }

  function new(string name = "dma350_sc_item");
    super.new(name);
  endfunction

endclass : dma350_sc_item

`endif // DMA350_SC_ITEM__SV
