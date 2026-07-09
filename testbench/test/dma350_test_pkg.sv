//==============================================================================
// dma350_test_pkg.sv  -  Package test cho CoreLink DMA-350
//------------------------------------------------------------------------------
// Import env + tat ca VIP package, roi include: sequence agent -> virtual
// sequence -> base test -> 10 testcase.
// Compile SAU tat ca cac package con (xem dma350.f).
//==============================================================================
`ifndef DMA350_TEST_PKG_SV
`define DMA350_TEST_PKG_SV

package dma350_test_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // VIP con (de test tao/config cac cfg object + dung sequence co san)
  import axi5_globals_pkg::*;
  import axi5_slave_pkg::*;
  import axi5_slave_seq_pkg::*;   // axi5_slave_read_seq / axi5_slave_write_seq (responder)
  import component_m_pkg::*;
  import axis_common_pkg::*;
  import axis_master_pkg::*;
  import axis_slave_pkg::*;       // axis_slave_always_ready_seq
  import boot_pkg::*;             // boot_*_seq
  import dma_irq_pkg::*;
  import crlp_pkg::*;             // crlp_por_seq / crlp_qch_cycle_seq / crlp_pch_seq
  import dma350_sc_pkg::*;        // dma350_sc_stop_seq / pause_seq / cti_seq ...
  import ral_pkg::*;

  // Env (scoreboard + virtual sequencer + dma350_env + dma_trig_item stub)
  import dma350_env_pkg::*;

  // ---- sequence cho agent (directed APB) : moi class 1 file ----
  `include "dma350_apb_write_seq.sv"
  `include "dma350_apb_read_seq.sv"

  // ---- virtual sequence : base truoc, roi moi vseq 1 file ----
  `include "dma350_vseq_base.sv"
  `include "dma350_vseq_reg_access.sv"
  `include "dma350_vseq_single_copy.sv"
  `include "dma350_vseq_fill.sv"
  `include "dma350_vseq_2d_copy.sv"
  `include "dma350_vseq_wrap.sv"
  `include "dma350_vseq_multi_channel.sv"
  `include "dma350_vseq_stop_pause.sv"
  `include "dma350_vseq_allch_stop_pause.sv"
  `include "dma350_vseq_lowpower.sv"
  `include "dma350_vseq_gpo.sv"

  // ---- base test ----
  `include "dma350_base_test.sv"

  // ---- 10 testcase ----
  `include "dma350_reg_access_test.sv"
  `include "dma350_single_copy_test.sv"
  `include "dma350_fill_test.sv"
  `include "dma350_2d_copy_test.sv"
  `include "dma350_wrap_test.sv"
  `include "dma350_multi_channel_test.sv"
  `include "dma350_stop_pause_test.sv"
  `include "dma350_allch_stop_pause_test.sv"
  `include "dma350_lowpower_test.sv"
  `include "dma350_gpo_test.sv"

endpackage : dma350_test_pkg

`endif // DMA350_TEST_PKG_SV
