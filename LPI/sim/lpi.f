// ============================================================================
// lpi.f - compile file list for the LPI VIP-to-VIP UVM testbench
// (UVM itself is added by the Makefile via UVM_FLAGS, do NOT add it here)
// Paths are relative to the sim/ directory where the Makefile runs.
//
// Only PACKAGES + interfaces + top are compiled; individual class files are
// pulled in by `include from each package, resolved via the +incdir list.
//
// Child SEQUENCES live in tb/seq (lpi_{q,p}channel_seq_pkg). The common
// SCOREBOARD is `include`d by the env package (tb/env/lpi_scoreboard.sv).
// ============================================================================

// include dirs (one per folder that holds class/types files)
+incdir+../tb/common
+incdir+../tb/if
+incdir+../tb/agents/qchannel
+incdir+../tb/agents/qchannel/master
+incdir+../tb/agents/qchannel/slave
+incdir+../tb/agents/pchannel
+incdir+../tb/agents/pchannel/master
+incdir+../tb/agents/pchannel/slave
+incdir+../tb/seq
+incdir+../tb/env
+incdir+../tb/vseq
+incdir+../tb/test

// interfaces
../tb/if/lpi_qchannel_if.sv
../tb/if/lpi_pchannel_if.sv

// VIP packages (master + slave agents, monitor, coverage)
../tb/agents/qchannel/lpi_qchannel_pkg.sv
../tb/agents/pchannel/lpi_pchannel_pkg.sv

// sequence packages (separate folder tb/seq)
../tb/seq/lpi_qchannel_seq_pkg.sv
../tb/seq/lpi_pchannel_seq_pkg.sv

// environment package (virtual sequencer + common scoreboard + env)
../tb/env/lpi_env_pkg.sv

// virtual sequences (separate package/folder)
../tb/vseq/lpi_vseq_pkg.sv

// tests
../tb/test/lpi_test_pkg.sv

// top
../tb/top/tb_top.sv
