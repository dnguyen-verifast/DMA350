# ============================================================================
# run_questa.do - Mentor/Siemens Questa run script
# Usage:  vsim -c -do run_questa.do            (batch)
#         or from Questa GUI:  do run_questa.do
# Override test:  vsim -c -do "set TEST lpi_qchannel_test; do run_questa.do"
# ============================================================================
if {![info exists TEST]} { set TEST lpi_smoke_test }

vlib work
vmap work work

# Compile (UVM ships with Questa: -L mtiUvm / use built-in uvm)
vlog -sv +incdir+../tb/common +incdir+../tb/if \
    +incdir+$env(UVM_HOME)/src $env(UVM_HOME)/src/uvm_pkg.sv \
    -f filelist.f

vsim -c -voptargs="+acc" tb_top \
    +UVM_TESTNAME=$TEST \
    +UVM_VERBOSITY=UVM_LOW \
    -do "run -all; coverage save lpi.ucdb; quit -f"
