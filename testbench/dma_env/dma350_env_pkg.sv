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
//       dma350_sc_if, apb interface, axi_stream_if, boot_if, crlp/lpi if...
//
// THU TU INCLUDE noi bo:
//   1) dma_trig_item.sv    (STUB - xem file, thay bang VIP trigger that)
//   2) dma350_scoreboard.sv
//   3) dma350_env.sv
//==============================================================================
`ifndef DMA350_ENV_PKG_SV
`define DMA350_ENV_PKG_SV

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

  // ---- (1) STUB trigger item (scoreboard phu thuoc) ----
  `include "dma_trig_item.sv"

  // ---- (2) scoreboard ----
  `include "dma350_scoreboard.sv"

  // ---- (3) virtual sequencer (truoc env - env tham chieu no) ----
  `include "dma350_virtual_sequencer.sv"

  // ---- (4) env ----
  `include "dma350_env.sv"

endpackage : dma350_env_pkg

`endif // DMA350_ENV_PKG_SV
