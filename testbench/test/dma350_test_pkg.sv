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
  // ---- vseq 1D : gom trong vseq/1d/axi_only_operation/ ----
  //   Path "1d/<nhom>/..." resolve qua +incdir+testbench/test/vseq (xem dma350.f).
  //   dma350_vseq_1d_single_base PHAI dung truoc 21 vseq con (chung ke thua no).
  //---------------------------------------------------------------------------
  `include "1d/axi_only_operation/dma350_vseq_1d_single_base.sv"
  // 1D co ban (SRC==DES==16), giu lam smoke test nhanh
  `include "1d/axi_only_operation/dma350_vseq_1d_single_continue.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_fill.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_wrap.sv"
  // TRM 5.2.2 (List of cases for 1D WRAP) : 7 kich ban x 3 XTYPE = 21 vseq
  `include "1d/axi_only_operation/dma350_vseq_1d_single_src0_des0_cont.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_src0_des0_wrap.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_src0_des0_fill.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_src0_desgt_cont.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_src0_desgt_wrap.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_src0_desgt_fill.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_srcgt_des0_cont.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_srcgt_des0_wrap.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_srcgt_des0_fill.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_src_eq_des_cont.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_src_eq_des_wrap.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_src_eq_des_fill.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_src_gt_des_cont.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_src_gt_des_wrap.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_src_gt_des_fill.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_src_lt_des_cont.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_src_lt_des_wrap.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_src_lt_des_fill.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_desinc0_cont.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_desinc0_wrap.sv"
  `include "1d/axi_only_operation/dma350_vseq_1d_single_desinc0_fill.sv"

  //---------------------------------------------------------------------------
  // ---- vseq TRIGGER (TRM 5.4) : gom trong vseq/1d/trigger/ ----
  //   base truoc, roi 4 reqtype x 2 mode + internal + 3 software trigger
  //---------------------------------------------------------------------------
  `include "1d/trigger/dma350_vseq_trig_base.sv"
  // SOURCE trigger = COMMAND mode, 4 request type (DES khong dung trigger)
  `include "1d/trigger/dma350_vseq_trig_srccmd_single.sv"
  `include "1d/trigger/dma350_vseq_trig_srccmd_last_single.sv"
  `include "1d/trigger/dma350_vseq_trig_srccmd_block.sv"
  `include "1d/trigger/dma350_vseq_trig_srccmd_last_block.sv"
  // SOURCE trigger = FLOW CONTROL mode, 4 request type
  `include "1d/trigger/dma350_vseq_trig_srcflow_single.sv"
  `include "1d/trigger/dma350_vseq_trig_srcflow_last_single.sv"
  `include "1d/trigger/dma350_vseq_trig_srcflow_block.sv"
  `include "1d/trigger/dma350_vseq_trig_srcflow_last_block.sv"
  // KET HOP hai phia src/des (TRM Fig 5-15 / 5-17 / 5-18)
  `include "1d/trigger/dma350_vseq_trig_bothcmd.sv"
  `include "1d/trigger/dma350_vseq_trig_srcflow_descmd.sv"
  `include "1d/trigger/dma350_vseq_trig_srccmd_desblock.sv"
  // Internal trigger connection (channel -> channel)
  `include "1d/trigger/dma350_vseq_trig_internal.sv"
  // Software triggers
  `include "1d/trigger/dma350_vseq_trig_sw_src.sv"
  `include "1d/trigger/dma350_vseq_trig_sw_des.sv"
  `include "1d/trigger/dma350_vseq_trig_sw_trigout_ack.sv"

  //---------------------------------------------------------------------------
  // ---- vseq COMMAND LINKING (TRM 5.7) : gom trong vseq/1d/cmdlink/ ----
  //   base truoc; hai luong: APB-then-link va autoboot-then-link.
  //   Moi vseq mot bo HEADER descriptor khac nhau.
  //---------------------------------------------------------------------------
  `include "1d/cmdlink/dma350_vseq_cmdlink_base.sv"
  `include "1d/cmdlink/dma350_vseq_cmdlink_apb_2cmd.sv"
  `include "1d/cmdlink/dma350_vseq_cmdlink_apb_3cmd.sv"
  `include "1d/cmdlink/dma350_vseq_cmdlink_apb_regclear.sv"
  `include "1d/cmdlink/dma350_vseq_cmdlink_apb_noregclear.sv"
  `include "1d/cmdlink/dma350_vseq_cmdlink_apb_ctrl_only.sv"
  `include "1d/cmdlink/dma350_vseq_cmdlink_apb_addr_size.sv"
  `include "1d/cmdlink/dma350_vseq_cmdlink_apb_transcfg.sv"
  `include "1d/cmdlink/dma350_vseq_cmdlink_apb_xaddrinc.sv"
  `include "1d/cmdlink/dma350_vseq_cmdlink_boot_single.sv"
  `include "1d/cmdlink/dma350_vseq_cmdlink_boot_chain.sv"
  `include "1d/cmdlink/dma350_vseq_cmdlink_apb_example.sv"

  //---------------------------------------------------------------------------
  // ---- vseq STREAM MODE (TRM 5.5) : gom trong vseq/1d/stream/ ----
  //   base truoc; 4 che do (no-stream / out-only / in-only / in+out) + 1 bien the
  //---------------------------------------------------------------------------
  `include "1d/stream/dma350_vseq_stream_base.sv"
  `include "1d/stream/dma350_vseq_stream_no_stream.sv"
  `include "1d/stream/dma350_vseq_stream_out_only.sv"
  `include "1d/stream/dma350_vseq_stream_in_only.sv"
  `include "1d/stream/dma350_vseq_stream_in_out.sv"
  `include "1d/stream/dma350_vseq_stream_in_out_hw.sv"

  //---------------------------------------------------------------------------
  // ---- vseq LIFECYCLE / EXECUTION STATES (TRM 5.6) : gom trong vseq/1d/lifecycle/
  //   base truoc; Disabled / Enabled / Paused / Stopped / Halted(CTI) / Error
  //---------------------------------------------------------------------------
  `include "1d/lifecycle/dma350_vseq_lifecycle_base.sv"
  `include "1d/lifecycle/dma350_vseq_lifecycle_disabled.sv"
  `include "1d/lifecycle/dma350_vseq_lifecycle_enabled.sv"
  `include "1d/lifecycle/dma350_vseq_lifecycle_paused.sv"
  `include "1d/lifecycle/dma350_vseq_lifecycle_stopped.sv"
  `include "1d/lifecycle/dma350_vseq_lifecycle_halted_cti.sv"
  `include "1d/lifecycle/dma350_vseq_lifecycle_error.sv"

  //---------------------------------------------------------------------------
  // ---- vseq POWER / LPI (TRM 4.6 / 5.9.1) : gom trong vseq/1d/power/ ----
  //   Active / Retention / P-Channel / Q-Channel
  //---------------------------------------------------------------------------
  `include "1d/power/dma350_vseq_power_base.sv"
  `include "1d/power/dma350_vseq_power_active.sv"
  `include "1d/power/dma350_vseq_power_retention.sv"
  `include "1d/power/dma350_vseq_power_pchannel.sv"
  `include "1d/power/dma350_vseq_power_qchannel.sv"

  //---------------------------------------------------------------------------
  // ---- vseq SECURITY / PRIVILEGE (AxPROT) : gom trong vseq/1d/secpriv/ ----
  //   Secure / Non-secure / Privileged / Unprivileged
  //---------------------------------------------------------------------------
  `include "1d/secpriv/dma350_vseq_secpriv_base.sv"
  `include "1d/secpriv/dma350_vseq_secpriv_secure.sv"
  `include "1d/secpriv/dma350_vseq_secpriv_nonsecure.sv"
  `include "1d/secpriv/dma350_vseq_secpriv_privileged.sv"
  `include "1d/secpriv/dma350_vseq_secpriv_unprivileged.sv"

  //---------------------------------------------------------------------------
  // ---- vseq 2D (TRM 5.3) : gom trong vseq/2d/<nhom>/ ----
  //   Chia theo mode giong cach lam cua 1D:
  //     axi_only_operation  wrap_fill  corner_cases  transform  template
  //     trigger  stream  cmdlink  lifecycle  power  secpriv  arbitration  negative
  //   dma350_vseq_2d_base la base CHUNG cua ca bo -> de o goc 2d/.
  //   Ba base con lai (2d_trig / 2d_stream / 2d_link) nam trong thu muc nhom cua
  //   minh va KE THUA base 1D tuong ung -> PHAI include SAU cac nhom trigger /
  //   stream / cmdlink o tren.
  //---------------------------------------------------------------------------
  `include "2d/dma350_vseq_2d_base.sv"
  `include "2d/trigger/dma350_vseq_2d_trig_base.sv"
  `include "2d/stream/dma350_vseq_2d_stream_base.sv"
  `include "2d/cmdlink/dma350_vseq_2d_link_base.sv"
  // GROUP A - 2D co ban (TRM 5.3.1)
  `include "2d/axi_only_operation/dma350_vseq_2d_basic_continue.sv"
  `include "2d/axi_only_operation/dma350_vseq_2d_basic_xaddrinc.sv"
  `include "2d/axi_only_operation/dma350_vseq_2d_basic_negstride.sv"
  `include "2d/axi_only_operation/dma350_vseq_2d_basic_as_1d.sv"
  `include "2d/axi_only_operation/dma350_vseq_2d_basic_desinc0.sv"
  `include "2d/axi_only_operation/dma350_vseq_2d_basic_transize_byte.sv"
  `include "2d/axi_only_operation/dma350_vseq_2d_basic_transize_hword.sv"
  `include "2d/axi_only_operation/dma350_vseq_2d_basic_large_frame.sv"
  // GROUP B - WRAP / FILL reshaping (TRM 5.3.2)
  `include "2d/wrap_fill/dma350_vseq_2d_wrap_x_srclt.sv"
  `include "2d/wrap_fill/dma350_vseq_2d_wrap_y_srclt.sv"
  `include "2d/wrap_fill/dma350_vseq_2d_fill_y.sv"
  `include "2d/wrap_fill/dma350_vseq_2d_fill_x.sv"
  `include "2d/wrap_fill/dma350_vseq_2d_wrap_xy.sv"
  `include "2d/wrap_fill/dma350_vseq_2d_wrap_x_eq.sv"
  `include "2d/wrap_fill/dma350_vseq_2d_wrap_srcy_gt_desy.sv"
  `include "2d/wrap_fill/dma350_vseq_2d_cont_srcy_lt_desy.sv"
  `include "2d/wrap_fill/dma350_vseq_2d_cont_srcx_gt_desx.sv"
  `include "2d/wrap_fill/dma350_vseq_2d_wrap_srcx_gt_desx.sv"
  `include "2d/wrap_fill/dma350_vseq_2d_fill_x_ycont.sv"
  `include "2d/wrap_fill/dma350_vseq_2d_reshape_same_area.sv"
  `include "2d/wrap_fill/dma350_vseq_2d_reshape_1d_to_2d.sv"
  `include "2d/wrap_fill/dma350_vseq_2d_reshape_2d_to_1d.sv"
  // GROUP C - 19 corner case Table 5-3 (TRM 5.3.2.1)
  `include "2d/corner_cases/dma350_vseq_2d_corner_01.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_02.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_03.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_04.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_05.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_06.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_07.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_08.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_09.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_10.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_11.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_12.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_13.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_14.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_15.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_16.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_17.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_18.sv"
  `include "2d/corner_cases/dma350_vseq_2d_corner_19.sv"
  // GROUP D - Bien hinh mirror/rotate/transpose (TRM 5.3.1 Fig 5-7)
  `include "2d/transform/dma350_vseq_2d_xform_mirror_x.sv"
  `include "2d/transform/dma350_vseq_2d_xform_mirror_y.sv"
  `include "2d/transform/dma350_vseq_2d_xform_rotate_180.sv"
  `include "2d/transform/dma350_vseq_2d_xform_rotate_90.sv"
  `include "2d/transform/dma350_vseq_2d_xform_rotate_270.sv"
  `include "2d/transform/dma350_vseq_2d_xform_transpose.sv"
  `include "2d/transform/dma350_vseq_2d_xform_overlap_stride.sv"
  `include "2d/transform/dma350_vseq_2d_xform_stride_zero.sv"
  // GROUP E - Templated transfers (TRM 5.3.3)
  `include "2d/template/dma350_vseq_2d_tmplt_src_1d.sv"
  `include "2d/template/dma350_vseq_2d_tmplt_des_1d.sv"
  `include "2d/template/dma350_vseq_2d_tmplt_both_1d.sv"
  // GROUP F - Trigger tren lenh 2D (TRM 5.4)
  `include "2d/trigger/dma350_vseq_2d_trig_sw_cmd.sv"
  `include "2d/trigger/dma350_vseq_2d_trig_hw_cmd_src.sv"
  `include "2d/trigger/dma350_vseq_2d_trig_hw_cmd_des.sv"
  `include "2d/trigger/dma350_vseq_2d_trig_hw_cmd_both.sv"
  `include "2d/trigger/dma350_vseq_2d_trig_internal.sv"
  `include "2d/trigger/dma350_vseq_2d_trig_out.sv"
  `include "2d/trigger/dma350_vseq_2d_trig_out_sw_ack.sv"
  `include "2d/trigger/dma350_vseq_2d_trig_last_block.sv"
  `include "2d/trigger/dma350_vseq_2d_trig_pending.sv"
  `include "2d/trigger/dma350_vseq_2d_trig_sw_des.sv"
  // GROUP G - AXI4-Stream tren lenh 2D (TRM 5.5, Table 5-6)
  `include "2d/stream/dma350_vseq_2d_stream_out_only.sv"
  `include "2d/stream/dma350_vseq_2d_stream_in_only.sv"
  `include "2d/stream/dma350_vseq_2d_stream_in_out.sv"
  `include "2d/stream/dma350_vseq_2d_stream_cont_cont.sv"
  `include "2d/stream/dma350_vseq_2d_stream_cont_fill.sv"
  `include "2d/stream/dma350_vseq_2d_stream_early_tlast.sv"
  `include "2d/stream/dma350_vseq_2d_stream_no_stream.sv"
  `include "2d/stream/dma350_vseq_2d_stream_pkt_boundary.sv"
  // GROUP H - Command link / autoboot / autorestart (TRM 5.7)
  `include "2d/cmdlink/dma350_vseq_2d_link_chain.sv"
  `include "2d/cmdlink/dma350_vseq_2d_link_regclear.sv"
  `include "2d/cmdlink/dma350_vseq_2d_link_ysize_update.sv"
  `include "2d/cmdlink/dma350_vseq_2d_link_stride_update.sv"
  `include "2d/cmdlink/dma350_vseq_2d_link_1d_to_2d.sv"
  `include "2d/cmdlink/dma350_vseq_2d_boot_single.sv"
  `include "2d/cmdlink/dma350_vseq_2d_boot_chain.sv"
  `include "2d/cmdlink/dma350_vseq_2d_autorestart_cnt.sv"
  `include "2d/cmdlink/dma350_vseq_2d_autorestart_reload.sv"
  // GROUP I - Lifecycle / execution states (TRM 5.6)
  `include "2d/lifecycle/dma350_vseq_2d_life_pause_resume.sv"
  `include "2d/lifecycle/dma350_vseq_2d_life_pause_twice.sv"
  `include "2d/lifecycle/dma350_vseq_2d_life_stop.sv"
  `include "2d/lifecycle/dma350_vseq_2d_life_disable.sv"
  `include "2d/lifecycle/dma350_vseq_2d_life_halt_cti.sv"
  `include "2d/lifecycle/dma350_vseq_2d_life_done_pause.sv"
  `include "2d/lifecycle/dma350_vseq_2d_life_err_bus.sv"
  `include "2d/lifecycle/dma350_vseq_2d_life_err_cfg.sv"
  `include "2d/lifecycle/dma350_vseq_2d_life_allch_stop.sv"
  // GROUP J - Power / LPI (TRM 4.6, 5.9.1)
  `include "2d/power/dma350_vseq_2d_power_active.sv"
  `include "2d/power/dma350_vseq_2d_power_retention.sv"
  `include "2d/power/dma350_vseq_2d_power_pchannel.sv"
  `include "2d/power/dma350_vseq_2d_power_qchannel.sv"
  // GROUP K - Security / privilege (TRM 5.10)
  `include "2d/secpriv/dma350_vseq_2d_sec_secure.sv"
  `include "2d/secpriv/dma350_vseq_2d_sec_nonsecure.sv"
  `include "2d/secpriv/dma350_vseq_2d_sec_priv.sv"
  `include "2d/secpriv/dma350_vseq_2d_sec_unpriv.sv"
  `include "2d/secpriv/dma350_vseq_2d_sec_mixed.sv"
  // GROUP L - Arbitration / nhieu channel (TRM 5.8)
  `include "2d/arbitration/dma350_vseq_2d_arb_two_ch.sv"
  `include "2d/arbitration/dma350_vseq_2d_arb_prio.sv"
  `include "2d/arbitration/dma350_vseq_2d_arb_2d_vs_1d.sv"
  `include "2d/arbitration/dma350_vseq_2d_arb_four_ch.sv"
  // GROUP X - Test AM / rang buoc cheo bi cam
  `include "2d/negative/dma350_vseq_2d_neg_ytype_wrap_stream.sv"
  `include "2d/negative/dma350_vseq_2d_neg_xtype_wrap_stream.sv"
  `include "2d/negative/dma350_vseq_2d_neg_xtype_fill_stream.sv"
  `include "2d/negative/dma350_vseq_2d_neg_flowctrl_src_2d.sv"
  `include "2d/negative/dma350_vseq_2d_neg_flowctrl_des_2d.sv"
  `include "2d/negative/dma350_vseq_2d_neg_flowctrl_wrap_2d.sv"
  `include "2d/negative/dma350_vseq_2d_neg_flowctrl_stream_2d.sv"
  `include "2d/negative/dma350_vseq_2d_neg_transize_gt_bus.sv"
  `include "2d/negative/dma350_vseq_2d_neg_trigsel_out_of_range.sv"
  `include "2d/negative/dma350_vseq_2d_neg_tmplt_with_2d_src.sv"
  `include "2d/negative/dma350_vseq_2d_neg_tmplt_with_2d_des.sv"
  `include "2d/negative/dma350_vseq_2d_neg_ytype_disabled_ysize.sv"
  `include "2d/negative/dma350_vseq_2d_neg_zero_dest_area.sv"

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
  // ---- testcase 1D : gom trong testcases/1d/axi_only_operation/ ----
  //   Path "1d/<nhom>/..." resolve qua +incdir+testbench/test/testcases (xem dma350.f).
  //---------------------------------------------------------------------------
  // 1D co ban (SRC==DES==16), smoke test nhanh
  `include "1d/axi_only_operation/dma350_1d_single_continue_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_fill_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_wrap_test.sv"
  // TRM 5.2.2 (List of cases for 1D WRAP) : 7 kich ban x 3 XTYPE = 21 test
  `include "1d/axi_only_operation/dma350_1d_single_src0_des0_cont_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_src0_des0_wrap_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_src0_des0_fill_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_src0_desgt_cont_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_src0_desgt_wrap_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_src0_desgt_fill_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_srcgt_des0_cont_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_srcgt_des0_wrap_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_srcgt_des0_fill_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_src_eq_des_cont_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_src_eq_des_wrap_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_src_eq_des_fill_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_src_gt_des_cont_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_src_gt_des_wrap_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_src_gt_des_fill_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_src_lt_des_cont_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_src_lt_des_wrap_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_src_lt_des_fill_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_desinc0_cont_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_desinc0_wrap_test.sv"
  `include "1d/axi_only_operation/dma350_1d_single_desinc0_fill_test.sv"

  //---------------------------------------------------------------------------
  // ---- 15 testcase TRIGGER (TRM 5.4) : gom trong testcases/1d/trigger/ ----
  //---------------------------------------------------------------------------
  `include "1d/trigger/dma350_trig_srccmd_single_test.sv"
  `include "1d/trigger/dma350_trig_srccmd_last_single_test.sv"
  `include "1d/trigger/dma350_trig_srccmd_block_test.sv"
  `include "1d/trigger/dma350_trig_srccmd_last_block_test.sv"
  `include "1d/trigger/dma350_trig_srcflow_single_test.sv"
  `include "1d/trigger/dma350_trig_srcflow_last_single_test.sv"
  `include "1d/trigger/dma350_trig_srcflow_block_test.sv"
  `include "1d/trigger/dma350_trig_srcflow_last_block_test.sv"
  `include "1d/trigger/dma350_trig_bothcmd_test.sv"
  `include "1d/trigger/dma350_trig_srcflow_descmd_test.sv"
  `include "1d/trigger/dma350_trig_srccmd_desblock_test.sv"
  `include "1d/trigger/dma350_trig_internal_test.sv"
  `include "1d/trigger/dma350_trig_sw_src_test.sv"
  `include "1d/trigger/dma350_trig_sw_des_test.sv"
  `include "1d/trigger/dma350_trig_sw_trigout_ack_test.sv"

  //---------------------------------------------------------------------------
  // ---- 10 testcase COMMAND LINKING (TRM 5.7) : gom trong testcases/1d/cmdlink/ ----
  //---------------------------------------------------------------------------
  `include "1d/cmdlink/dma350_cmdlink_apb_2cmd_test.sv"
  `include "1d/cmdlink/dma350_cmdlink_apb_3cmd_test.sv"
  `include "1d/cmdlink/dma350_cmdlink_apb_regclear_test.sv"
  `include "1d/cmdlink/dma350_cmdlink_apb_noregclear_test.sv"
  `include "1d/cmdlink/dma350_cmdlink_apb_ctrl_only_test.sv"
  `include "1d/cmdlink/dma350_cmdlink_apb_addr_size_test.sv"
  `include "1d/cmdlink/dma350_cmdlink_apb_transcfg_test.sv"
  `include "1d/cmdlink/dma350_cmdlink_apb_xaddrinc_test.sv"
  `include "1d/cmdlink/dma350_cmdlink_boot_single_test.sv"
  `include "1d/cmdlink/dma350_cmdlink_boot_chain_test.sv"
  `include "1d/cmdlink/dma350_cmdlink_apb_example_test.sv"

  //---------------------------------------------------------------------------
  // ---- 5 testcase STREAM MODE (TRM 5.5) : gom trong testcases/1d/stream/ ----
  //---------------------------------------------------------------------------
  `include "1d/stream/dma350_stream_no_stream_test.sv"
  `include "1d/stream/dma350_stream_out_only_test.sv"
  `include "1d/stream/dma350_stream_in_only_test.sv"
  `include "1d/stream/dma350_stream_in_out_test.sv"
  `include "1d/stream/dma350_stream_in_out_hw_test.sv"

  //---------------------------------------------------------------------------
  // ---- 6 testcase LIFECYCLE (TRM 5.6) : gom trong testcases/1d/lifecycle/ ----
  //---------------------------------------------------------------------------
  `include "1d/lifecycle/dma350_lifecycle_disabled_test.sv"
  `include "1d/lifecycle/dma350_lifecycle_enabled_test.sv"
  `include "1d/lifecycle/dma350_lifecycle_paused_test.sv"
  `include "1d/lifecycle/dma350_lifecycle_stopped_test.sv"
  `include "1d/lifecycle/dma350_lifecycle_halted_cti_test.sv"
  `include "1d/lifecycle/dma350_lifecycle_error_test.sv"

  //---------------------------------------------------------------------------
  // ---- 4 testcase POWER / LPI : gom trong testcases/1d/power/ ----
  //---------------------------------------------------------------------------
  `include "1d/power/dma350_power_active_test.sv"
  `include "1d/power/dma350_power_retention_test.sv"
  `include "1d/power/dma350_power_pchannel_test.sv"
  `include "1d/power/dma350_power_qchannel_test.sv"

  //---------------------------------------------------------------------------
  // ---- 4 testcase SECURITY / PRIVILEGE : gom trong testcases/1d/secpriv/ ----
  //---------------------------------------------------------------------------
  `include "1d/secpriv/dma350_secpriv_secure_test.sv"
  `include "1d/secpriv/dma350_secpriv_nonsecure_test.sv"
  `include "1d/secpriv/dma350_secpriv_privileged_test.sv"
  `include "1d/secpriv/dma350_secpriv_unprivileged_test.sv"

  //---------------------------------------------------------------------------
  // ---- 114 testcase 2D (TRM 5.3) : gom trong testcases/2d/ ----
  //---------------------------------------------------------------------------
  // GROUP A - 2D co ban (TRM 5.3.1)
  `include "2d/axi_only_operation/dma350_2d_basic_continue_test.sv"
  `include "2d/axi_only_operation/dma350_2d_basic_xaddrinc_test.sv"
  `include "2d/axi_only_operation/dma350_2d_basic_negstride_test.sv"
  `include "2d/axi_only_operation/dma350_2d_basic_as_1d_test.sv"
  `include "2d/axi_only_operation/dma350_2d_basic_desinc0_test.sv"
  `include "2d/axi_only_operation/dma350_2d_basic_transize_byte_test.sv"
  `include "2d/axi_only_operation/dma350_2d_basic_transize_hword_test.sv"
  `include "2d/axi_only_operation/dma350_2d_basic_large_frame_test.sv"
  // GROUP B - WRAP / FILL reshaping (TRM 5.3.2)
  `include "2d/wrap_fill/dma350_2d_wrap_x_srclt_test.sv"
  `include "2d/wrap_fill/dma350_2d_wrap_y_srclt_test.sv"
  `include "2d/wrap_fill/dma350_2d_fill_y_test.sv"
  `include "2d/wrap_fill/dma350_2d_fill_x_test.sv"
  `include "2d/wrap_fill/dma350_2d_wrap_xy_test.sv"
  `include "2d/wrap_fill/dma350_2d_wrap_x_eq_test.sv"
  `include "2d/wrap_fill/dma350_2d_wrap_srcy_gt_desy_test.sv"
  `include "2d/wrap_fill/dma350_2d_cont_srcy_lt_desy_test.sv"
  `include "2d/wrap_fill/dma350_2d_cont_srcx_gt_desx_test.sv"
  `include "2d/wrap_fill/dma350_2d_wrap_srcx_gt_desx_test.sv"
  `include "2d/wrap_fill/dma350_2d_fill_x_ycont_test.sv"
  `include "2d/wrap_fill/dma350_2d_reshape_same_area_test.sv"
  `include "2d/wrap_fill/dma350_2d_reshape_1d_to_2d_test.sv"
  `include "2d/wrap_fill/dma350_2d_reshape_2d_to_1d_test.sv"
  // GROUP C - 19 corner case Table 5-3 (TRM 5.3.2.1)
  `include "2d/corner_cases/dma350_2d_corner_01_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_02_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_03_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_04_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_05_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_06_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_07_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_08_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_09_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_10_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_11_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_12_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_13_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_14_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_15_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_16_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_17_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_18_test.sv"
  `include "2d/corner_cases/dma350_2d_corner_19_test.sv"
  // GROUP D - Bien hinh mirror/rotate/transpose (TRM 5.3.1 Fig 5-7)
  `include "2d/transform/dma350_2d_xform_mirror_x_test.sv"
  `include "2d/transform/dma350_2d_xform_mirror_y_test.sv"
  `include "2d/transform/dma350_2d_xform_rotate_180_test.sv"
  `include "2d/transform/dma350_2d_xform_rotate_90_test.sv"
  `include "2d/transform/dma350_2d_xform_rotate_270_test.sv"
  `include "2d/transform/dma350_2d_xform_transpose_test.sv"
  `include "2d/transform/dma350_2d_xform_overlap_stride_test.sv"
  `include "2d/transform/dma350_2d_xform_stride_zero_test.sv"
  // GROUP E - Templated transfers (TRM 5.3.3)
  `include "2d/template/dma350_2d_tmplt_src_1d_test.sv"
  `include "2d/template/dma350_2d_tmplt_des_1d_test.sv"
  `include "2d/template/dma350_2d_tmplt_both_1d_test.sv"
  // GROUP F - Trigger tren lenh 2D (TRM 5.4)
  `include "2d/trigger/dma350_2d_trig_sw_cmd_test.sv"
  `include "2d/trigger/dma350_2d_trig_hw_cmd_src_test.sv"
  `include "2d/trigger/dma350_2d_trig_hw_cmd_des_test.sv"
  `include "2d/trigger/dma350_2d_trig_hw_cmd_both_test.sv"
  `include "2d/trigger/dma350_2d_trig_internal_test.sv"
  `include "2d/trigger/dma350_2d_trig_out_test.sv"
  `include "2d/trigger/dma350_2d_trig_out_sw_ack_test.sv"
  `include "2d/trigger/dma350_2d_trig_last_block_test.sv"
  `include "2d/trigger/dma350_2d_trig_pending_test.sv"
  `include "2d/trigger/dma350_2d_trig_sw_des_test.sv"
  // GROUP G - AXI4-Stream tren lenh 2D (TRM 5.5, Table 5-6)
  `include "2d/stream/dma350_2d_stream_out_only_test.sv"
  `include "2d/stream/dma350_2d_stream_in_only_test.sv"
  `include "2d/stream/dma350_2d_stream_in_out_test.sv"
  `include "2d/stream/dma350_2d_stream_cont_cont_test.sv"
  `include "2d/stream/dma350_2d_stream_cont_fill_test.sv"
  `include "2d/stream/dma350_2d_stream_early_tlast_test.sv"
  `include "2d/stream/dma350_2d_stream_no_stream_test.sv"
  `include "2d/stream/dma350_2d_stream_pkt_boundary_test.sv"
  // GROUP H - Command link / autoboot / autorestart (TRM 5.7)
  `include "2d/cmdlink/dma350_2d_link_chain_test.sv"
  `include "2d/cmdlink/dma350_2d_link_regclear_test.sv"
  `include "2d/cmdlink/dma350_2d_link_ysize_update_test.sv"
  `include "2d/cmdlink/dma350_2d_link_stride_update_test.sv"
  `include "2d/cmdlink/dma350_2d_link_1d_to_2d_test.sv"
  `include "2d/cmdlink/dma350_2d_boot_single_test.sv"
  `include "2d/cmdlink/dma350_2d_boot_chain_test.sv"
  `include "2d/cmdlink/dma350_2d_autorestart_cnt_test.sv"
  `include "2d/cmdlink/dma350_2d_autorestart_reload_test.sv"
  // GROUP I - Lifecycle / execution states (TRM 5.6)
  `include "2d/lifecycle/dma350_2d_life_pause_resume_test.sv"
  `include "2d/lifecycle/dma350_2d_life_pause_twice_test.sv"
  `include "2d/lifecycle/dma350_2d_life_stop_test.sv"
  `include "2d/lifecycle/dma350_2d_life_disable_test.sv"
  `include "2d/lifecycle/dma350_2d_life_halt_cti_test.sv"
  `include "2d/lifecycle/dma350_2d_life_done_pause_test.sv"
  `include "2d/lifecycle/dma350_2d_life_err_bus_test.sv"
  `include "2d/lifecycle/dma350_2d_life_err_cfg_test.sv"
  `include "2d/lifecycle/dma350_2d_life_allch_stop_test.sv"
  // GROUP J - Power / LPI (TRM 4.6, 5.9.1)
  `include "2d/power/dma350_2d_power_active_test.sv"
  `include "2d/power/dma350_2d_power_retention_test.sv"
  `include "2d/power/dma350_2d_power_pchannel_test.sv"
  `include "2d/power/dma350_2d_power_qchannel_test.sv"
  // GROUP K - Security / privilege (TRM 5.10)
  `include "2d/secpriv/dma350_2d_sec_secure_test.sv"
  `include "2d/secpriv/dma350_2d_sec_nonsecure_test.sv"
  `include "2d/secpriv/dma350_2d_sec_priv_test.sv"
  `include "2d/secpriv/dma350_2d_sec_unpriv_test.sv"
  `include "2d/secpriv/dma350_2d_sec_mixed_test.sv"
  // GROUP L - Arbitration / nhieu channel (TRM 5.8)
  `include "2d/arbitration/dma350_2d_arb_two_ch_test.sv"
  `include "2d/arbitration/dma350_2d_arb_prio_test.sv"
  `include "2d/arbitration/dma350_2d_arb_2d_vs_1d_test.sv"
  `include "2d/arbitration/dma350_2d_arb_four_ch_test.sv"
  // GROUP X - Test AM / rang buoc cheo bi cam
  `include "2d/negative/dma350_2d_neg_ytype_wrap_stream_test.sv"
  `include "2d/negative/dma350_2d_neg_xtype_wrap_stream_test.sv"
  `include "2d/negative/dma350_2d_neg_xtype_fill_stream_test.sv"
  `include "2d/negative/dma350_2d_neg_flowctrl_src_2d_test.sv"
  `include "2d/negative/dma350_2d_neg_flowctrl_des_2d_test.sv"
  `include "2d/negative/dma350_2d_neg_flowctrl_wrap_2d_test.sv"
  `include "2d/negative/dma350_2d_neg_flowctrl_stream_2d_test.sv"
  `include "2d/negative/dma350_2d_neg_transize_gt_bus_test.sv"
  `include "2d/negative/dma350_2d_neg_trigsel_out_of_range_test.sv"
  `include "2d/negative/dma350_2d_neg_tmplt_with_2d_src_test.sv"
  `include "2d/negative/dma350_2d_neg_tmplt_with_2d_des_test.sv"
  `include "2d/negative/dma350_2d_neg_ytype_disabled_ysize_test.sv"
  `include "2d/negative/dma350_2d_neg_zero_dest_area_test.sv"

endpackage : dma350_test_pkg

`endif // DMA350_TEST_PKG_SV
