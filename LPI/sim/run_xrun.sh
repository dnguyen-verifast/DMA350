#!/usr/bin/env bash
# ============================================================================
# run_xrun.sh - Cadence Xcelium single-step run
# Usage:  ./run_xrun.sh [TESTNAME]
# ============================================================================
set -e
TEST=${1:-lpi_smoke_test}

xrun -64bit -sv -uvm \
    +incdir+../tb/common +incdir+../tb/if \
    -f filelist.f \
    -access +rwc \
    +UVM_TESTNAME=${TEST} \
    +UVM_VERBOSITY=UVM_LOW \
    -l ${TEST}.log
