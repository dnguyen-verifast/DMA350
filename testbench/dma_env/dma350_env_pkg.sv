//==============================================================================
// dma350_env_pkg.sv  -  Package env top cho CoreLink DMA-350
//------------------------------------------------------------------------------
// Gom scoreboard + env cua DMA-350 va import tat ca package VIP con.
//
// DIEU KIEN COMPILE (dua vao filelist / +incdir):
//   * Cac package VIP con da compile TRUOC:
//       axi5_globals_pkg, axi5_base_tx_pkg, axi5_slave_pkg,
//       component_m_pkg (APB master), axis_common_pkg, axis_master_pkg,
//       axis_slave_pkg, boot_pkg, dma_irq_pkg, crlp_pkg, dma350_sc_pkg,
//       ral_pkg
//   * Cac INTERFACE (compile o top-level, ngoai package):
//       dma350_sc_if, apb interface, axi_stream_if, boot_if, crlp/lpi if,
//       dma_trig_if (interface TONG 6 signal cua 1 cap cong trigger)
//
// THU TU INCLUDE noi bo:
//   1) dma350_scoreboard.sv
//   2) dma350_virtual_sequencer.sv
//   3) dma350_env.sv
//==============================================================================
`ifndef DMA350_ENV_PKG_SV
`define DMA350_ENV_PKG_SV

// Macro kich thuoc SC (mirror tu dma350_sc_if / dma350_sc_pkg). dma350_scoreboard
// dung `DMA350_SC_MAX_GPO_WIDTH; mot so simulator (vd Questa mac dinh) KHONG cho
// macro "leak" sang file/compilation-unit khac, nen dinh nghia lai o day truoc
// khi include scoreboard. ifndef-guard => an toan neu da define noi khac (cung 8/32).
`ifndef DMA350_SC_MAX_CHANNELS
  `define DMA350_SC_MAX_CHANNELS 8
`endif
`ifndef DMA350_SC_MAX_GPO_WIDTH
  `define DMA350_SC_MAX_GPO_WIDTH 32
`endif

package dma350_env_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ---- import cac VIP con (mang vao scope cac class agent/cfg/item) ----
  import axi5_globals_pkg::*;   // DATA_WIDTH, enum resp/burst...
  import axi5_slave_pkg::*;     // axi5_slave_agent, _config, axi5_slave_tx, mon_proxy
  import component_m_pkg::*;     // apb_agent_master, apb_seq_item_master
  import axis_common_pkg::*;     // axis_seq_item
  import axis_master_pkg::*;     // axis_master_agent, axis_master_cfg
  import axis_slave_pkg::*;      // axis_slave_agent, axis_slave_cfg
  import boot_pkg::*;            // boot_agent, boot_agent_cfg, boot_seq_item
  import dma_irq_pkg::*;         // dma_irq_agent, dma_irq_config, dma_irq_item
  import crlp_pkg::*;            // crlp_agent, crlp_config, crlp_seq_item + enum LPI
  import dma350_sc_pkg::*;       // dma350_sc_agent, dma350_sc_cfg, dma350_sc_item
  import ral_pkg::*;             // reg_env, ral_dma350, reg2apb_adapter, apb_seq_item
  // Trigger VIP (CTI). dma_trig_item la item that ma scoreboard.process_trigger
  // tieu thu (observed_reqtype/observed_acktype/comb_ack_seen).
  // KHONG import dma_trig_out_pkg: trig-out do DMAC tu phat, chi can auto-ack
  // trong dma_trig_in_driver -> khong dung agent trig_out rieng.
  import dma_trig_common_pkg::*; // dma_trig_item, dma_trig_cfg, enum reqtype/acktype
  import dma_trig_in_pkg::*;     // dma_trig_in_agent, _sequencer, cac sequence

  // ---- (1) scoreboard ----
  `include "dma350_scoreboard.sv"

  // ---- (2) virtual sequencer (truoc env - env tham chieu no) ----
  `include "dma350_virtual_sequencer.sv"

  // ---- (3) env ----
  `include "dma350_env.sv"

endpackage : dma350_env_pkg

`endif // DMA350_ENV_PKG_SV
