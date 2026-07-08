//==============================================================================
// ral_pkg.sv  -  Package RAL cho CoreLink DMA-350
//------------------------------------------------------------------------------
// Gom toan bo model thanh ghi (UVM RAL) + adapter + reg_env vao 1 package.
//
// THU TU INCLUDE la BAT BUOC:
//   1) apb_seq_item        : bus item cho adapter + predictor
//   2) tung *_reg          : dinh nghia uvm_reg (member cua block_config)
//   3) *_reg_block_config   : block config (dung cac uvm_reg o tren)
//   4) ral_dma350           : block cha (dung cac block_config)
//   5) reg2apb_adapter      : adapter reg<->apb
//   6) reg_env              : env chua ral_model + predictor + adapter
//
// LUU Y: file interface (apb_interface.sv) KHONG include vao package (interface
// phai compile o scope top-level). ral_pkg chi chua class.
//==============================================================================
`ifndef RAL_PKG_SV
`define RAL_PKG_SV

package ral_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ---- (1) bus item ----
  `include "apb_seq_item.sv"

  // ---- (2) DMACH : 38 thanh ghi kenh ----
  `include "DMACH/ch_cmd_reg.sv"
  `include "DMACH/ch_status_reg.sv"
  `include "DMACH/ch_intren_reg.sv"
  `include "DMACH/ch_ctrl_reg.sv"
  `include "DMACH/ch_srcaddr_reg.sv"
  `include "DMACH/ch_srcaddrhi_reg.sv"
  `include "DMACH/ch_desaddr_reg.sv"
  `include "DMACH/ch_desaddrhi_reg.sv"
  `include "DMACH/ch_xsize_reg.sv"
  `include "DMACH/ch_xsizehi_reg.sv"
  `include "DMACH/ch_srctranscfg_reg.sv"
  `include "DMACH/ch_destranscfg_reg.sv"
  `include "DMACH/ch_xaddrinc_reg.sv"
  `include "DMACH/ch_yaddrstride_reg.sv"
  `include "DMACH/ch_fillval_reg.sv"
  `include "DMACH/ch_ysize_reg.sv"
  `include "DMACH/ch_tmpltcfg_reg.sv"
  `include "DMACH/ch_srctmplt_reg.sv"
  `include "DMACH/ch_destmplt_reg.sv"
  `include "DMACH/ch_srctrigincfg_reg.sv"
  `include "DMACH/ch_destrigincfg_reg.sv"
  `include "DMACH/ch_trigoutcfg_reg.sv"
  `include "DMACH/ch_gpoen0_reg.sv"
  `include "DMACH/ch_gpoval0_reg.sv"
  `include "DMACH/ch_streamintcfg_reg.sv"
  `include "DMACH/ch_linkattr_reg.sv"
  `include "DMACH/ch_autocfg_reg.sv"
  `include "DMACH/ch_linkaddr_reg.sv"
  `include "DMACH/ch_linkaddrhi_reg.sv"
  `include "DMACH/ch_gporead0_reg.sv"
  `include "DMACH/ch_errinfo_reg.sv"
  `include "DMACH/ch_aidr_reg.sv"
  `include "DMACH/ch_iidr_reg.sv"
  `include "DMACH/ch_buildcfg0_reg.sv"
  `include "DMACH/ch_buildcfg1_reg.sv"
  `include "DMACH/ch_issuecap_reg.sv"
  `include "DMACH/ch_wrkregptr_reg.sv"
  `include "DMACH/ch_wrkregval_reg.sv"
  `include "DMACH/dmach_reg_block_config.sv"

  // ---- (2) DMASECCFG ----
  `include "DMASECCFG/scfg_ctrl_reg.sv"
  `include "DMASECCFG/scfg_intrstatus_reg.sv"
  `include "DMASECCFG/scfg_chsec0_reg.sv"
  `include "DMASECCFG/scfg_triginsec0_reg.sv"
  `include "DMASECCFG/scfg_trigoutsec0_reg.sv"
  `include "DMASECCFG/dmaseccfg_reg_block_config.sv"

  // ---- (2) DMASECCTRL ----
  `include "DMASECCTRL/sec_ctrl_reg.sv"
  `include "DMASECCTRL/sec_status_reg.sv"
  `include "DMASECCTRL/sec_chcfg_reg.sv"
  `include "DMASECCTRL/sec_chptr_reg.sv"
  `include "DMASECCTRL/sec_chintrstatus0_reg.sv"
  `include "DMASECCTRL/sec_signalptr_reg.sv"
  `include "DMASECCTRL/sec_signalval_reg.sv"
  `include "DMASECCTRL/sec_statusptr_reg.sv"
  `include "DMASECCTRL/sec_statusval_reg.sv"
  `include "DMASECCTRL/dmasecctrl_reg_block_config.sv"

  // ---- (2) DMANSECCTRL ----
  `include "DMANSECCTRL/nsec_ctrl_reg.sv"
  `include "DMANSECCTRL/nsec_status_reg.sv"
  `include "DMANSECCTRL/nsec_chcfg_reg.sv"
  `include "DMANSECCTRL/nsec_chptr_reg.sv"
  `include "DMANSECCTRL/nsec_chintrstatus0_reg.sv"
  `include "DMANSECCTRL/nsec_signalptr_reg.sv"
  `include "DMANSECCTRL/nsec_signalval_reg.sv"
  `include "DMANSECCTRL/nsec_statusptr_reg.sv"
  `include "DMANSECCTRL/nsec_statusval_reg.sv"
  `include "DMANSECCTRL/dmansecctrl_reg_block_config.sv"

  // ---- (2) DMAINFO ----
  `include "DMAINFO/dma_buildcfg0_reg.sv"
  `include "DMAINFO/dma_buildcfg1_reg.sv"
  `include "DMAINFO/dma_buildcfg2_reg.sv"
  `include "DMAINFO/iidr_reg.sv"
  `include "DMAINFO/aidr_reg.sv"
  `include "DMAINFO/pidr0_reg.sv"
  `include "DMAINFO/pidr1_reg.sv"
  `include "DMAINFO/pidr2_reg.sv"
  `include "DMAINFO/pidr3_reg.sv"
  `include "DMAINFO/pidr4_reg.sv"
  `include "DMAINFO/cidr0_reg.sv"
  `include "DMAINFO/cidr1_reg.sv"
  `include "DMAINFO/cidr2_reg.sv"
  `include "DMAINFO/cidr3_reg.sv"
  `include "DMAINFO/dmainfo_reg_block_config.sv"

  // ---- (4) block cha ----
  `include "ral_dma350.sv"

  // ---- (5) adapter ----
  `include "reg2apb_adapter.sv"

  // ---- (6) reg_env (ral_model + predictor + adapter) ----
  `include "reg_env.sv"

endpackage : ral_pkg

`endif // RAL_PKG_SV
