//============================================================================
// dma_trig_cfg.sv
// Knob-only agent configuration. The virtual interface is fetched directly by
// each agent (typed handle):
//   * dma_trig_in_agent  -> dma_trig_if     (interface TONG 6 signal: <TI>+<TO>)
//   * dma_trig_out_agent -> dma_trig_out_if (chi dung trong tb standalone cua VIP)
//============================================================================
`ifndef DMA_TRIG_CFG_SV
`define DMA_TRIG_CFG_SV

class dma_trig_cfg extends uvm_object;

  // UVM agent knobs.
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  bit                     en_cov    = 1;

  // Port index this agent represents (<TI> or <TO>).
  int unsigned            port_id   = 0;

  // Trigger-input usage mode -> drives the scoreboard ack_type semantics.
  dma_trig_mode_e         mode      = DMA_TRIG_MODE_CMD;

  // Flow-control block size the requester uses (mirror of TRIGINBLKSIZE); the
  // scoreboard uses it to check LAST_OKAY placement / short final block.
  int unsigned            blk_size  = 4;

  // ---- trig-out auto-ack (dung khi interface tong dma_trig_if) --------------
  // trig-out do DMAC TU PHAT: khong can stimulus, chi can ack lai de DMAC HA
  // trig_out_req xuong (hoan tat 4-phase). Luong auto-ack chay nen trong
  // dma_trig_in_driver dam nhiem.
  //   trigout_auto_ack  = 0 -> KHONG ack (mo phong SW-ack qua SWTRIGOUTACK,
  //                            hoac test stall: channel treo cho ack)
  //   trigout_ack_delay     -> so chu ky tu khi thay req den khi keo ack
  bit                     trigout_auto_ack  = 1;
  int unsigned            trigout_ack_delay = 0;

  `uvm_object_utils_begin(dma_trig_cfg)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_field_int (en_cov,                             UVM_ALL_ON)
    `uvm_field_int (port_id,                            UVM_ALL_ON | UVM_DEC)
    `uvm_field_enum(dma_trig_mode_e,         mode,      UVM_ALL_ON)
    `uvm_field_int (blk_size,                           UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (trigout_auto_ack,                   UVM_ALL_ON)
    `uvm_field_int (trigout_ack_delay,                  UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

  function new(string name = "dma_trig_cfg");
    super.new(name);
  endfunction

endclass : dma_trig_cfg

`endif // DMA_TRIG_CFG_SV
