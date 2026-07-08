#!/usr/bin/env bash
# ============================================================================
# run_vcs.sh - Synopsys VCS run script
# Usage:  ./run_vcs.sh [TESTNAME]
# Default test: lpi_smoke_test
# ============================================================================
set -e
TEST=${1:-lpi_smoke_test}

vcs -full64 -sverilog -ntb_opts uvm-1.2 \
    +incdir+../tb/common +incdir+../tb/if \
    -f filelist.f \
    -debug_access+all \
    -o simv

./simv +UVM_TESTNAME=${TEST} +UVM_VERBOSITY=UVM_LOW -l ${TEST}.log
