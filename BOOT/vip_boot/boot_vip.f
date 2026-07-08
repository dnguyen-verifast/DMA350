// -----------------------------------------------------------------------------
// boot_vip.f  -  compile file list for the DMA-350 boot VIP + example TB
//
// Usage examples:
//   Questa  : vlog -sv +incdir+src +incdir+tb -f boot_vip.f && vsim boot_tb_top
//   VCS     : vcs -sverilog +incdir+src +incdir+tb -f boot_vip.f
//   Xcelium : xrun -sv -incdir src -incdir tb -f boot_vip.f
//
// (UVM must be available; add the simulator's UVM library/flag as required.)
// -----------------------------------------------------------------------------

+incdir+src
+incdir+tb

// Interface + SVA (compiled outside the package)
src/boot_if.sv
src/boot_sva.sv

// VIP package
src/boot_pkg.sv

// Example testbench
tb/boot_dut_stub.sv
tb/boot_test_pkg.sv
tb/boot_tb_top.sv
