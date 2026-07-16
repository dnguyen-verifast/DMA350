//==============================================================================
// dma350_virtual_sequencer.sv
//------------------------------------------------------------------------------
// Virtual sequencer cua moi truong DMA-350: giu handle toi sequencer cua TAT CA
// cac agent active trong dma350_env. Virtual sequence dieu khien testbench qua
// p_sequencer.<handle> (xem test/vseq/dma350_vseq_base.sv).
//
// Handle nao = null nghia la agent tuong ung dang PASSIVE (khong co sequencer).
// dma_irq_agent luon passive -> KHONG co handle o day.
//
// Duoc gan trong dma350_env.connect_phase.
//==============================================================================
`ifndef DMA350_VIRTUAL_SEQUENCER_SV
`define DMA350_VIRTUAL_SEQUENCER_SV

class dma350_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(dma350_virtual_sequencer)

  // ---- APB register bus (cau hinh DMA) ----
  apb_sequencer_master        apb_seqr_h;

  // ---- AXI5 slave M0 (read-path) : responder write/read ----
  axi5_slave_write_sequencer  axi5_slv0_write_seqr_h;
  axi5_slave_read_sequencer   axi5_slv0_read_seqr_h;

  // ---- AXI5 slave M1 (write-path) : responder write/read ----
  axi5_slave_write_sequencer  axi5_slv1_write_seqr_h;
  axi5_slave_read_sequencer   axi5_slv1_read_seqr_h;

  // ---- AXI-Stream in (master VIP: peripheral -> DMA) ----
  axis_master_sequencer       axis_mst_seqr_h;

  // ---- AXI-Stream out (slave VIP: DMA -> peripheral, lai TREADY) ----
  axis_slave_sequencer        axis_slv_seqr_h;

  // ---- Boot / autoboot config pins ----
  boot_sequencer              boot_seqr_h;

  // ---- Clock / Reset / Low-Power ----
  crlp_sequencer              crlp_seqr_h;

  // ---- Status / Control (allch stop-pause, CTI halt/restart) ----
  dma350_sc_sequencer         sc_seqr_h;

  // ---- Trigger (CTI) : 4 cong, bi danh t0..t3 (khop NUM_TRIGGER_IN=4 cua RTL)
  // Moi sequencer lai phia trig-in (requester) cua cap cong tuong ung. Phia
  // trig-out do driver AUTO-ACK, khong can sequencer.
  //   vd: dma_trig_in_single_seq s; s.start(p_sequencer.trig_seqr_h[0]);
  dma_trig_in_sequencer       trig_seqr_h[4];

  function new(string name = "dma350_virtual_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass : dma350_virtual_sequencer

`endif // DMA350_VIRTUAL_SEQUENCER_SV
