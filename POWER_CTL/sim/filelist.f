// -------------------------------------------------------------------------
// Compile file list for the CRLP agent testbench.
//   Usage (examples):
//     Questa : vlog -sv +incdir+../tb +incdir+../sim -f filelist.f
//     VCS    : vcs  -sverilog +incdir+../tb +incdir+../sim -f filelist.f
//     Xcelium: xrun -sv +incdir+../tb +incdir+../sim -f filelist.f
// -------------------------------------------------------------------------
+incdir+../tb
+incdir+../sim

// Interface (compiled outside the package)
../tb/crlp_if.sv

// Agent package (pulls in all *.svh via `include)
../tb/crlp_pkg.sv

// DUT stub + top
../sim/crlp_dut_stub.sv
../sim/crlp_tb_top.sv
