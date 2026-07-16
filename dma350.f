//==============================================================================
// dma350.f  -  Filelist compile FULL testbench DMA-350 (RTL DUT + env + test + top)
//------------------------------------------------------------------------------
// Dung (khuyen nghi - qua Makefile trong sim/):
//   cd sim
//   make compile
//   make simulate test=dma350_single_copy_test uvm_verbosity=UVM_MEDIUM
//   make regression testlist_name=dma350_regression.list
//
// Makefile doc file nay bang `vlog -F ../dma350.f` : voi -F (chu HOA), duong
// dan tuong doi BEN TRONG .f resolve theo vi tri cua chinh file .f (goc repo)
// -> chay tu sim/ van dung. (-f thuong resolve theo CWD.)
//
// Dung tay (khong qua make):
//   VCS   : vcs -sverilog -ntb_opts uvm-1.2 -debug_access+all -f dma350.f -o simv
//           ./simv +UVM_TESTNAME=dma350_base_test
//   Questa: vlog -sv -f dma350.f ; vsim -c dma350_tb_top +UVM_TESTNAME=dma350_base_test \
//           -voptargs=+acc -do "run -all"
//
// LUU Y:
//   * UVM do simulator cung cap (-ntb_opts uvm / -uvm). Neu dung UVM rieng,
//     them +incdir+$UVM_HOME/src va $UVM_HOME/src/uvm_pkg.sv o DAU filelist.
//   * BACKDOOR RAL can quyen truy cap HDL: VCS them -debug_access+all;
//     Questa them -voptargs=+acc (neu khong, uvm_hdl_read se fail).
//   * Thu tu compile QUAN TRONG:
//       globals pkg -> interface -> package VIP -> BFM -> RTL -> env -> test -> top
//==============================================================================

// ----------------------------------------------------------------------------
// +incdir : noi chua cac file `include cua tung package
// ----------------------------------------------------------------------------
+incdir+.
+incdir+testbench/dma_env
+incdir+testbench/test
+incdir+testbench/test/seq
+incdir+testbench/test/vseq
+incdir+testbench/test/testcases
+incdir+AMBA_AXI5/src/globals
+incdir+AMBA_AXI5/src/hvl_top/base_tx
+incdir+AMBA_AXI5/src/hvl_top/slave
+incdir+AMBA_AXI5/src/hvl_top/test/sequences/slave_sequences
+incdir+APB4/vip2vip/apb_master/tb
+incdir+APB4/vip2vip/interface
+incdir+AXIS/tb/common
+incdir+AXIS/tb/agent_master
+incdir+AXIS/tb/agent_slave
+incdir+AXIS/tb/test/seq_m
+incdir+AXIS/tb/test/seq_l
+incdir+BOOT/vip_boot/src
+incdir+IRQ
+incdir+POWER_CTL/tb
+incdir+Status_Control/dma350_sc_agent/pkg
+incdir+Status_Control/dma350_sc_agent/config
+incdir+Status_Control/dma350_sc_agent/seq_item
+incdir+Status_Control/dma350_sc_agent/components
+incdir+Status_Control/dma350_sc_agent/sequences
+incdir+RAL_DMA350
+incdir+CTI/common
+incdir+CTI/trig_in

// ----------------------------------------------------------------------------
// (1) GLOBALS package (axi5_if import axi5_globals_pkg -> phai compile truoc)
// ----------------------------------------------------------------------------
AMBA_AXI5/src/globals/axi5_globals_pkg.sv

// ----------------------------------------------------------------------------
// (2) INTERFACES (compile o top-level, truoc cac package/BFM tham chieu chung)
// ----------------------------------------------------------------------------
AXIS/tb/axi_stream_if.sv
BOOT/vip_boot/src/boot_if.sv
POWER_CTL/tb/crlp_if.sv
IRQ/dma_irq_if.sv
APB4/vip2vip/interface/apb_interface.sv
Status_Control/dma350_sc_agent/interface/dma350_sc_if.sv
AMBA_AXI5/src/hdl_top/axi5_interface/axi5_if.sv
// Interface TONG cua 1 cap cong trigger (6 signal: trig-in + trig-out).
// Thay cho dma_trig_in_if/dma_trig_out_if (chi dung boi tb standalone cua CTI).
CTI/rtl/dma_trig_if.sv

// ----------------------------------------------------------------------------
// (3) PACKAGE VIP con (thu tu phu thuoc)
// ----------------------------------------------------------------------------
AMBA_AXI5/src/hvl_top/base_tx/axi5_base_tx_pkg.sv
AMBA_AXI5/src/hvl_top/slave/axi5_slave_pkg.sv
AMBA_AXI5/src/hvl_top/test/sequences/slave_sequences/axi5_slave_seq_pkg.sv
APB4/vip2vip/apb_master/tb/component_m_pkg.sv
AXIS/tb/common/axis_cfg_pkg.sv
AXIS/tb/common/axis_common_pkg.sv
AXIS/tb/agent_master/axis_master_pkg.sv
AXIS/tb/agent_slave/axis_slave_pkg.sv
BOOT/vip_boot/src/boot_pkg.sv
IRQ/dma_irq_pkg.sv
POWER_CTL/tb/crlp_pkg.sv
Status_Control/dma350_sc_agent/pkg/dma350_sc_pkg.sv
RAL_DMA350/ral_pkg.sv
// Trigger VIP (CTI). Chi common + trig_in: trig-out do DMAC tu phat, driver
// trig-in auto-ack -> khong can dma_trig_out_pkg.
CTI/common/dma_trig_common_pkg.sv
CTI/trig_in/dma_trig_in_pkg.sv

// ----------------------------------------------------------------------------
// (4) AXI5 slave BFM (driver + monitor; import axi5_slave_pkg -> sau (3)).
//     KHONG dung wrapper axi5_slave_agent_bfm (set config key global se
//     conflict giua M0/M1) - tb_top instantiate BFM truc tiep + set key scoped.
// ----------------------------------------------------------------------------
AMBA_AXI5/src/hdl_top/slave_agent_bfm/axi5_slave_driver_bfm.sv
AMBA_AXI5/src/hdl_top/slave_agent_bfm/axi5_slave_monitor_bfm.sv

// ----------------------------------------------------------------------------
// (5) RTL DUT : CoreLink DMA-350 (RTL_DMA_350)
// ----------------------------------------------------------------------------
RTL_DMA_350/dma350_pkg.sv
RTL_DMA_350/dma350_byte_fifo.sv
RTL_DMA_350/dma350_burst.sv
RTL_DMA_350/dma350_trigger.sv
RTL_DMA_350/dma350_lpi.sv
RTL_DMA_350/dma350_ch_regs.sv
RTL_DMA_350/dma350_axi_node.sv
RTL_DMA_350/dma350_channel.sv
RTL_DMA_350/dma350_top.sv

// ----------------------------------------------------------------------------
// (6) ENV + TEST + TOP
//     dma_env/  : dma_trig_item (stub) + dma350_scoreboard + dma350_env (include
//                 boi dma350_env_pkg qua +incdir+dma_env)
//     test/     : dma350_base_test (include boi dma350_test_pkg qua +incdir+test)
// ----------------------------------------------------------------------------
testbench/dma_env/dma350_env_pkg.sv
testbench/test/dma350_test_pkg.sv
dma350_tb_top.sv
