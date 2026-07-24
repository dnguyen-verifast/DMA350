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
  // Command-link: HDR_* / dia chi / anh vi du + bo nho descriptor nap tay.
  // vseq cmdlink NAP vao cmdlink_mem; hook trong axi5_slave_driver_proxy (guard
  // +define+DMA350_CMDLINK_HOOK) doc ra khi DUT fetch descriptor (arcmdlink=1).
  import dma350_cmdlink_mem_pkg::*;

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

  //---------------------------------------------------------------------------
  // ---- vseq TRIGGER (TRM 5.4) : gom trong vseq/trigger/ ----
  //   base truoc, roi 4 reqtype x 2 mode + internal + 3 software trigger
  //---------------------------------------------------------------------------
  `include "trigger/dma350_vseq_trig_base.sv"
  // SOURCE trigger = COMMAND mode, 4 request type (DES khong dung trigger)
  `include "trigger/dma350_vseq_trig_srccmd_single.sv"
  `include "trigger/dma350_vseq_trig_srccmd_last_single.sv"
  `include "trigger/dma350_vseq_trig_srccmd_block.sv"
  `include "trigger/dma350_vseq_trig_srccmd_last_block.sv"
  // SOURCE trigger = FLOW CONTROL mode, 4 request type
  `include "trigger/dma350_vseq_trig_srcflow_single.sv"
  `include "trigger/dma350_vseq_trig_srcflow_last_single.sv"
  `include "trigger/dma350_vseq_trig_srcflow_block.sv"
  `include "trigger/dma350_vseq_trig_srcflow_last_block.sv"
  // KET HOP hai phia src/des (TRM Fig 5-15 / 5-17 / 5-18)
  `include "trigger/dma350_vseq_trig_bothcmd.sv"
  `include "trigger/dma350_vseq_trig_srcflow_descmd.sv"
  `include "trigger/dma350_vseq_trig_srccmd_desblock.sv"
  // Internal trigger connection (channel -> channel)
  `include "trigger/dma350_vseq_trig_internal.sv"
  // Software triggers
  `include "trigger/dma350_vseq_trig_sw_src.sv"
  `include "trigger/dma350_vseq_trig_sw_des.sv"
  `include "trigger/dma350_vseq_trig_sw_trigout_ack.sv"

  //---------------------------------------------------------------------------
  // ---- vseq COMMAND LINKING (TRM 5.7) : gom trong vseq/cmdlink/ ----
  //   base truoc; hai luong: APB-then-link va autoboot-then-link.
  //   Moi vseq mot bo HEADER descriptor khac nhau.
  //---------------------------------------------------------------------------
  `include "cmdlink/dma350_vseq_cmdlink_base.sv"
  `include "cmdlink/dma350_vseq_cmdlink_apb_2cmd.sv"
  `include "cmdlink/dma350_vseq_cmdlink_apb_3cmd.sv"
  `include "cmdlink/dma350_vseq_cmdlink_apb_regclear.sv"
  `include "cmdlink/dma350_vseq_cmdlink_apb_noregclear.sv"
  `include "cmdlink/dma350_vseq_cmdlink_apb_ctrl_only.sv"
  `include "cmdlink/dma350_vseq_cmdlink_apb_addr_size.sv"
  `include "cmdlink/dma350_vseq_cmdlink_apb_transcfg.sv"
  `include "cmdlink/dma350_vseq_cmdlink_apb_xaddrinc.sv"
  `include "cmdlink/dma350_vseq_cmdlink_boot_single.sv"
  `include "cmdlink/dma350_vseq_cmdlink_boot_chain.sv"
  `include "cmdlink/dma350_vseq_cmdlink_apb_example.sv"

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

  //---------------------------------------------------------------------------
  // ---- 15 testcase TRIGGER (TRM 5.4) : gom trong testcases/trigger/ ----
  //---------------------------------------------------------------------------
  `include "trigger/dma350_trig_srccmd_single_test.sv"
  `include "trigger/dma350_trig_srccmd_last_single_test.sv"
  `include "trigger/dma350_trig_srccmd_block_test.sv"
  `include "trigger/dma350_trig_srccmd_last_block_test.sv"
  `include "trigger/dma350_trig_srcflow_single_test.sv"
  `include "trigger/dma350_trig_srcflow_last_single_test.sv"
  `include "trigger/dma350_trig_srcflow_block_test.sv"
  `include "trigger/dma350_trig_srcflow_last_block_test.sv"
  `include "trigger/dma350_trig_bothcmd_test.sv"
  `include "trigger/dma350_trig_srcflow_descmd_test.sv"
  `include "trigger/dma350_trig_srccmd_desblock_test.sv"
  `include "trigger/dma350_trig_internal_test.sv"
  `include "trigger/dma350_trig_sw_src_test.sv"
  `include "trigger/dma350_trig_sw_des_test.sv"
  `include "trigger/dma350_trig_sw_trigout_ack_test.sv"

  //---------------------------------------------------------------------------
  // ---- 10 testcase COMMAND LINKING (TRM 5.7) : gom trong testcases/cmdlink/ ----
  //---------------------------------------------------------------------------
  `include "cmdlink/dma350_cmdlink_apb_2cmd_test.sv"
  `include "cmdlink/dma350_cmdlink_apb_3cmd_test.sv"
  `include "cmdlink/dma350_cmdlink_apb_regclear_test.sv"
  `include "cmdlink/dma350_cmdlink_apb_noregclear_test.sv"
  `include "cmdlink/dma350_cmdlink_apb_ctrl_only_test.sv"
  `include "cmdlink/dma350_cmdlink_apb_addr_size_test.sv"
  `include "cmdlink/dma350_cmdlink_apb_transcfg_test.sv"
  `include "cmdlink/dma350_cmdlink_apb_xaddrinc_test.sv"
  `include "cmdlink/dma350_cmdlink_boot_single_test.sv"
  `include "cmdlink/dma350_cmdlink_boot_chain_test.sv"
  `include "cmdlink/dma350_cmdlink_apb_example_test.sv"

endpackage : dma350_test_pkg

`endif // DMA350_TEST_PKG_SV
