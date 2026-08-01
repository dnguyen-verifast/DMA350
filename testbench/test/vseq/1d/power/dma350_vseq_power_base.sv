//==============================================================================
// dma350_vseq_power_base.sv
//------------------------------------------------------------------------------
// Base cho bo test POWER / LPI (TRM 4.6 / 5.9.1) - CH0. Cac che do (bang anh):
//   Active / Normal : full power, dang chay
//   Retention       : trang thai low-power GIU context (P-Channel -> RET)
//   P-Channel power : chuyen power-domain qua LPI P-Channel
//   Q-Channel clock : clock gating qua LPI Q-Channel
//
// Dung cac sequence CRLP co san (p_sequencer.crlp_seqr_h):
//   crlp_pch_seq       : yeu cau doi power state (target_state = PSTATE_*)
//   crlp_qch_cycle_seq : quiesce + wake clock (Q-Channel)
// PSTATE_* tu crlp_pkg: PSTATE_OFF=0, PSTATE_RET=4, PSTATE_ON_CLK=8, PSTATE_ON_FULL=F
//==============================================================================
`ifndef DMA350_VSEQ_POWER_BASE_SV
`define DMA350_VSEQ_POWER_BASE_SV

class dma350_vseq_power_base extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_power_base)

  int unsigned ch       = 0;
  bit [31:0]   src_addr = 32'h0004_0000;
  bit [31:0]   des_addr = 32'h0004_4000;
  int unsigned xsize    = 32;

  function new(string name = "dma350_vseq_power_base");
    super.new(name);
  endfunction

  // Chay mot copy 1D (full power) den DONE.
  virtual task run_copy();
    cfg_ch(.ch(ch), .src(src_addr), .des(des_addr), .xsize(xsize));
    enable_ch(ch);
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

  // Yeu cau doi P-Channel power state.
  virtual task pch_request(bit [3:0] state, string what);
    crlp_pch_seq p = crlp_pch_seq::type_id::create("pch");
    if (!p.randomize() with { target_state == state; })
      `uvm_error(get_type_name(), $sformatf("randomize pch (%s) that bai", what))
    `uvm_info(get_type_name(), $sformatf("P-Channel -> %s (0x%0h)", what, state), UVM_LOW)
    p.start(p_sequencer.crlp_seqr_h);
  endtask

  // Q-Channel: quiesce roi wake.
  virtual task qch_cycle(string what = "");
    crlp_qch_cycle_seq q = crlp_qch_cycle_seq::type_id::create("qch");
    `uvm_info(get_type_name(), $sformatf("Q-Channel quiesce/wake %s", what), UVM_LOW)
    q.start(p_sequencer.crlp_seqr_h);
  endtask

  virtual task body();
    super.body();                 // POR + responders
  endtask

endclass : dma350_vseq_power_base

`endif // DMA350_VSEQ_POWER_BASE_SV
