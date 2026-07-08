#==============================================================================
# Makefile for the CRLP (Clock / Reset / Low-Power) UVM agent testbench
#   Simulator : Mentor/Siemens Questa (vlib / vlog / vsim / vcover)
#   Run from  : POWER_CTL/sim
#
# Quick reference:
#   make compile
#   make simulate test=<test_name> uvm_verbosity=<LEVEL>
#   make all
#   make regression testlist_name=<list_file>
#   make clean
#
#   -s  : silent mode          make <target> -s
#   -n  : dry-run (just print)  make <target> -n
#   -i  : ignore errors         make <target> -i
#==============================================================================

# Ignore errors in these recipes (treat as success, keep going)
.IGNORE:
	compile
	simulate

# Silent recipes (print output only, not the command)
.SILENT:
	compile
	simulate
	usage
	compile_war_err
	simulate_war_err

#------------------------------------------------------------------------------
# Project variables
#------------------------------------------------------------------------------
TOP          = crlp_tb_top
COMPILE_F    = filelist.f
COMPILE_LOG  = crlp_compile.log

UVM_HOME   = /cadtools/mentor/Questa_10.6b/questasim/verilog_src/uvm-1.1c
UVM_FLAGS  = +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv
UVM_DPI    = /cadtools/mentor/Questa_10.6b/questasim/uvm-1.1c/linux/uvm_dpi

# Default test
ifndef test
override test = crlp_base_test
endif

# Default UVM verbosity
ifndef uvm_verbosity
override uvm_verbosity = UVM_MEDIUM
endif

# Default per-test output folder (= test name)
ifndef test_folder
override test_folder = $(test)
endif

#------------------------------------------------------------------------------
# Default target : usage
#------------------------------------------------------------------------------
usage:
	echo "";
	echo "-----------------------------------------------------------------";
	echo "----------------------- CRLP Makefile ---------------------------";
	echo "";
	echo "make target <options> <variable>=<value>";
	echo "";
	echo "To compile:";
	echo "  make compile";
	echo "";
	echo "To simulate a single test:";
	echo "  make simulate test=<test_name> uvm_verbosity=<VERBOSITY>";
	echo "  Example: make simulate test=crlp_base_test uvm_verbosity=UVM_HIGH";
	echo "";
	echo "To compile + simulate:";
	echo "  make all";
	echo "";
	echo "To run a regression:";
	echo "  make regression testlist_name=<regression.list>";
	echo "";
	echo "To clean:";
	echo "  make clean";
	echo "";
	echo "-----------------------------------------------------------------";
	echo "";

#------------------------------------------------------------------------------
# Compile everything, then simulate the default/selected test
#------------------------------------------------------------------------------
all:
	make clean; make compile; make simulate;

#------------------------------------------------------------------------------
# Compilation
#   +acc      : full visibility (needed for assertions / debug)
#   +cover    : code coverage,  +fcover : functional (covergroup) coverage
#------------------------------------------------------------------------------
compile:
	make clean_compile;
	vlib work;
	vlog -sv \
	+acc \
	+cover \
	+fcover \
	$(UVM_FLAGS) \
	-l $(COMPILE_LOG) \
	-f $(COMPILE_F)
	make compile_war_err

#------------------------------------------------------------------------------
# Simulation
#   Waveform, assertions, coverage (code + assert + directive + cvg) saved to
#   a per-test .ucdb; HTML coverage report generated at the end.
#   Add  -sv_seed random  for randomized seeds.
#------------------------------------------------------------------------------
simulate:
	mkdir $(test_folder)
	vsim -vopt \
	-sv_lib $(UVM_DPI) \
	work.$(TOP) \
	-voptargs=+acc=npr \
	-assertdebug \
	+UVM_PHASE_TRACE \
	+UVM_OBJECTION_TRACE \
	+UVM_TESTNAME=$(test) \
	+UVM_VERBOSITY=$(uvm_verbosity) \
	-l $(test_folder)/$(test).log \
	-sva \
	-coverage \
	-c -solvefaildebug \
	-do "log -r /*; add wave -r /*; coverage save -onexit -assert -directive -cvg -codeAll $(test_folder)/$(test)_coverage.ucdb; run -all; exit" \
	-wlf $(test_folder)/waveform.wlf
	make simulate_war_err
	# Per-test HTML coverage report
	vcover report -html $(test_folder)/$(test)_coverage.ucdb -htmldir $(test_folder)/html_cov_report -details
	# To view the waveform:  vsim -view $(test_folder)/waveform.wlf &

#------------------------------------------------------------------------------
# Regression + coverage merge
#   (regression_handling.py is expected to iterate the tests in the list and
#    call `make simulate test=<name>` for each — same flow as the AXI4 env.)
#------------------------------------------------------------------------------
regression:
	python regression_handling.py $(testlist_name)
	make merge_cov_report

merge_cov_report:
	rm -rf merged_coverage.ucdb merged_cov_html_report
	vcover merge merged_coverage.ucdb -64 */*.ucdb
	vcover report -html merged_coverage.ucdb -htmldir ./merged_cov_html_report -details
	echo "";
	echo "-----------------------------------------------------------------";
	echo "Merged coverage: firefox merged_cov_html_report/index.html &";
	echo "-----------------------------------------------------------------";
	echo "";

#------------------------------------------------------------------------------
# Clean
#------------------------------------------------------------------------------
clean:
	make clean_compile
	make clean_simulate

clean_compile:
	rm -rf work/ *_compile.log transcript waveform.wlf
	rm -rf merged_coverage.ucdb merged_cov_html_report

clean_simulate:
	rm -rf *_test* crlp_base_test

#------------------------------------------------------------------------------
# Report helpers
#------------------------------------------------------------------------------
compile_war_err:
	echo "";
	echo "-----------------------------------------------------------------";
	echo "------------------- Compilation Report --------------------------";
	echo "";
	grep "^\*\* " $(COMPILE_LOG);
	echo "";
	grep "^Error" $(COMPILE_LOG);
	echo "";
	echo "Log file path: $(COMPILE_LOG)";
	echo "";
	echo "-----------------------------------------------------------------";
	echo "";

simulate_war_err:
	echo "";
	echo "-----------------------------------------------------------------";
	echo "-------------------- Simulation Report --------------------------";
	echo "";
	echo "Simulator Errors";
	grep "Error" $(test_folder)/$(test).log;
	echo "";
	echo "UVM Fatal";
	grep "UVM_FATAL" $(test_folder)/$(test).log;
	echo "";
	echo "UVM Errors";
	grep "UVM_ERROR" $(test_folder)/$(test).log;
	echo "";
	echo "UVM Warnings";
	grep "UVM_WARNING" $(test_folder)/$(test).log;
	echo "";
	echo "Testname: $(test)";
	echo "Log file path: $(test_folder)/$(test).log";
	echo "Waveform: vsim -view $(test_folder)/waveform.wlf &";
	echo "Coverage: firefox $(test_folder)/html_cov_report/index.html &";
	echo "";
	echo "-----------------------------------------------------------------";
	echo "";
