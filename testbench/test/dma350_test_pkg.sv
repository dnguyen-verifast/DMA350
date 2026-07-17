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
  // Trigger VIP (CTI). KHONG import dma_trig_out_pkg: trig-out do DMAC tu phat,
  // driver trig-in tu auto-ack -> khong dung agent trig_out.
  import dma_trig_common_pkg::*;  // dma_trig_cfg, dma_trig_item, enum reqtype/mode
  import dma_trig_in_pkg::*;      // dma_trig_in_agent + dma_trig_in_*_seq

  // Env (scoreboard + virtual sequencer + dma350_env + dma_trig_item stub)
  import dma350_env_pkg::*;

  // ---- sequence cho agent (directed APB) : moi class 1 file ----
  `include "dma350_apb_write_seq.sv"
  `include "dma350_apb_read_seq.sv"

  // ---- virtual sequence : base truoc, roi moi vseq 1 file ----
  `include "dma350_vseq_base.sv"
  `include "dma350_vseq_reg_access.sv"
  `include "dma350_vseq_2d_copy.sv"
  `include "dma350_vseq_multi_channel.sv"
  `include "dma350_vseq_stop_pause.sv"
  `include "dma350_vseq_allch_stop_pause.sv"
  `include "dma350_vseq_lowpower.sv"
  `include "dma350_vseq_gpo.sv"

  //---------------------------------------------------------------------------
  // ---- vseq 1D : gom trong vseq/1d/ ----
  //   Path "1d/..." resolve qua +incdir+testbench/test/vseq (xem dma350.f).
  //   dma350_vseq_1d_single_base PHAI dung truoc 21 vseq con (chung ke thua no).
  //---------------------------------------------------------------------------
  `include "1d/dma350_vseq_1d_single_base.sv"
  // 1D co ban (SRC==DES==16), giu lam smoke test nhanh
  `include "1d/dma350_vseq_1d_single_continue.sv"
  `include "1d/dma350_vseq_1d_single_fill.sv"
  `include "1d/dma350_vseq_1d_single_wrap.sv"
  // TRM 5.2.2 (List of cases for 1D WRAP) : 7 kich ban x 3 XTYPE = 21 vseq
  `include "1d/dma350_vseq_1d_single_src0_des0_cont.sv"
  `include "1d/dma350_vseq_1d_single_src0_des0_wrap.sv"
  `include "1d/dma350_vseq_1d_single_src0_des0_fill.sv"
  `include "1d/dma350_vseq_1d_single_src0_desgt_cont.sv"
  `include "1d/dma350_vseq_1d_single_src0_desgt_wrap.sv"
  `include "1d/dma350_vseq_1d_single_src0_desgt_fill.sv"
  `include "1d/dma350_vseq_1d_single_srcgt_des0_cont.sv"
  `include "1d/dma350_vseq_1d_single_srcgt_des0_wrap.sv"
  `include "1d/dma350_vseq_1d_single_srcgt_des0_fill.sv"
  `include "1d/dma350_vseq_1d_single_src_eq_des_cont.sv"
  `include "1d/dma350_vseq_1d_single_src_eq_des_wrap.sv"
  `include "1d/dma350_vseq_1d_single_src_eq_des_fill.sv"
  `include "1d/dma350_vseq_1d_single_src_gt_des_cont.sv"
  `include "1d/dma350_vseq_1d_single_src_gt_des_wrap.sv"
  `include "1d/dma350_vseq_1d_single_src_gt_des_fill.sv"
  `include "1d/dma350_vseq_1d_single_src_lt_des_cont.sv"
  `include "1d/dma350_vseq_1d_single_src_lt_des_wrap.sv"
  `include "1d/dma350_vseq_1d_single_src_lt_des_fill.sv"
  `include "1d/dma350_vseq_1d_single_desinc0_cont.sv"
  `include "1d/dma350_vseq_1d_single_desinc0_wrap.sv"
  `include "1d/dma350_vseq_1d_single_desinc0_fill.sv"

  // ---- base test ----
  `include "dma350_base_test.sv"

  // ---- testcase chung ----
  `include "dma350_reg_access_test.sv"
  `include "dma350_2d_copy_test.sv"
  `include "dma350_multi_channel_test.sv"
  `include "dma350_stop_pause_test.sv"
  `include "dma350_allch_stop_pause_test.sv"
  `include "dma350_lowpower_test.sv"
  `include "dma350_gpo_test.sv"

  //---------------------------------------------------------------------------
  // ---- testcase 1D : gom trong testcases/1d/ ----
  //   Path "1d/..." resolve qua +incdir+testbench/test/testcases (xem dma350.f).
  //---------------------------------------------------------------------------
  // 1D co ban (SRC==DES==16), smoke test nhanh
  `include "1d/dma350_1d_single_continue_test.sv"
  `include "1d/dma350_1d_single_fill_test.sv"
  `include "1d/dma350_1d_single_wrap_test.sv"
  // TRM 5.2.2 (List of cases for 1D WRAP) : 7 kich ban x 3 XTYPE = 21 test
  `include "1d/dma350_1d_single_src0_des0_cont_test.sv"
  `include "1d/dma350_1d_single_src0_des0_wrap_test.sv"
  `include "1d/dma350_1d_single_src0_des0_fill_test.sv"
  `include "1d/dma350_1d_single_src0_desgt_cont_test.sv"
  `include "1d/dma350_1d_single_src0_desgt_wrap_test.sv"
  `include "1d/dma350_1d_single_src0_desgt_fill_test.sv"
  `include "1d/dma350_1d_single_srcgt_des0_cont_test.sv"
  `include "1d/dma350_1d_single_srcgt_des0_wrap_test.sv"
  `include "1d/dma350_1d_single_srcgt_des0_fill_test.sv"
  `include "1d/dma350_1d_single_src_eq_des_cont_test.sv"
  `include "1d/dma350_1d_single_src_eq_des_wrap_test.sv"
  `include "1d/dma350_1d_single_src_eq_des_fill_test.sv"
  `include "1d/dma350_1d_single_src_gt_des_cont_test.sv"
  `include "1d/dma350_1d_single_src_gt_des_wrap_test.sv"
  `include "1d/dma350_1d_single_src_gt_des_fill_test.sv"
  `include "1d/dma350_1d_single_src_lt_des_cont_test.sv"
  `include "1d/dma350_1d_single_src_lt_des_wrap_test.sv"
  `include "1d/dma350_1d_single_src_lt_des_fill_test.sv"
  `include "1d/dma350_1d_single_desinc0_cont_test.sv"
  `include "1d/dma350_1d_single_desinc0_wrap_test.sv"
  `include "1d/dma350_1d_single_desinc0_fill_test.sv"

endpackage : dma350_test_pkg

`endif // DMA350_TEST_PKG_SV
