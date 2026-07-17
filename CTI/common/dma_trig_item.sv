//============================================================================
// dma_trig_item.sv
// One trigger handshake transaction (a single req/ack 4-phase exchange).
// Carries stimulus for BOTH directions; a trig-in (requester) agent uses the
// req-side fields, a trig-out (responder) agent uses the ack-side fields.
//============================================================================
`ifndef DMA_TRIG_ITEM_SV
`define DMA_TRIG_ITEM_SV

class dma_trig_item extends uvm_sequence_item;

  // ---- trig-in (REQUESTER) stimulus : the VIP drives req/req_type ----
  rand [7:0]              port_id;
  rand dma_trig_reqtype_e reqtype;            // request type to drive
  rand int unsigned       pre_delay;          // idle cycles before asserting req
  // Error injection (illegal stimulus, off by default):
  rand bit                err_reqtype_change; // mutate req_type while req held
  rand dma_trig_reqtype_e err_reqtype_alt;    // value to switch to

  // ---- trig-out (RESPONDER) stimulus : the VIP drives ack ----
  rand int unsigned       ack_delay;          // cycles from req seen -> ack (can be huge = stall)
  rand bit                ack_passive;         // 1 => do NOT drive ack (SW-ack / stall test)

  // ---- captured by driver/monitor ----
  dma_trig_reqtype_e      observed_reqtype;
  dma_trig_acktype_e      observed_acktype;   // ack_type the DMAC returned (trig-in only)
  time                    t_req;
  time                    t_ack;
  int unsigned            latency_cycles;
  bit                     comb_ack_seen;      // ack in same cycle as req (illegal)

  `uvm_object_utils_begin(dma_trig_item)
    `uvm_field_enum(dma_trig_reqtype_e, reqtype,            UVM_ALL_ON)
    `uvm_field_int (pre_delay,                              UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (err_reqtype_change,                     UVM_ALL_ON)
    `uvm_field_enum(dma_trig_reqtype_e, err_reqtype_alt,    UVM_ALL_ON)
    `uvm_field_int (ack_delay,                              UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (ack_passive,                            UVM_ALL_ON)
    `uvm_field_enum(dma_trig_reqtype_e, observed_reqtype,   UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_enum(dma_trig_acktype_e, observed_acktype,   UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int (latency_cycles,                         UVM_ALL_ON | UVM_DEC | UVM_NOCOMPARE)
    `uvm_field_int (comb_ack_seen,                          UVM_ALL_ON | UVM_NOCOMPARE)
  `uvm_object_utils_end

  // Soft so high-level sequences can widen (e.g. a long stall delay).
  constraint c_delays  { soft pre_delay inside {[0:8]}; soft ack_delay inside {[0:8]}; }
  constraint c_err     { soft err_reqtype_change == 0; soft ack_passive == 0;
                         err_reqtype_change -> err_reqtype_alt != reqtype; }

  function new(string name = "dma_trig_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("reqtype=%s pre=%0d ackdly=%0d pass=%0d | obs_req=%s obs_ack=%s lat=%0d%s",
                     reqtype.name(), pre_delay, ack_delay, ack_passive,
                     observed_reqtype.name(), observed_acktype.name(),
                     latency_cycles, comb_ack_seen ? " COMB!" : "");
  endfunction

endclass : dma_trig_item

`endif // DMA_TRIG_ITEM_SV
