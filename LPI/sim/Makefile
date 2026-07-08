# =============================================================================
# Makefile - AMBA Low Power Interface (LPI) UVM VIP-to-VIP testbench
# Questa/ModelSim flow. Adapted from a standard AXI-Stream UVM Makefile.
#
# Quick start:
#   make compile
#   make simulate test=lpi_smoke_test    uvm_verbosity=UVM_LOW
#   make simulate test=lpi_qchannel_test
#   make simulate test=lpi_pchannel_test
#   make regression testlist_name=lpi_regression.list
# =============================================================================

# -s        : silent mode (command + output shown only in silent)
# -n / -p   : --just-print, prints recipe without running
# -i        : --ignore-errors, errors in recipes are ignored
#
#   make target -s
#   make target -n
#   make target -i

.IGNORE:
	compile
	simulate

# Targets that always run in silent mode
.SILENT:
	compile
	simulate
	usage

# -----------------------------------------------------------------------------
# Default target: usage help (runs when no target is given)
# -----------------------------------------------------------------------------
usage:
	echo "";
	echo "-----------------------------------------------------------------";
	echo "------------------------- Usage ---------------------------------";
	echo "";
	echo "make target <options> <variable>=<value>";
	echo "";
	echo "To compile use:"
	echo "make compile";
	echo "";
	echo "To simulate individual test:"
	echo "make simulate test=<test_name> uvm_verbosity=<VERBOSITY_LEVEL>";
	echo "";
	echo "Example:";
	echo "make simulate test=lpi_smoke_test uvm_verbosity=UVM_HIGH";
	echo "";
	echo "Available tests: lpi_smoke_test, lpi_qchannel_test, lpi_pchannel_test";
	echo "";
	echo "To run regression:"
	echo "make regression testlist_name=<regression_testlist_name.list>";
	echo "";
	echo "Example:";
	echo "make regression testlist_name=lpi_regression.list";
	echo "";
	echo "-----------------------------------------------------------------";
	echo "-----------------------------------------------------------------";
	echo "";

# -----------------------------------------------------------------------------
# Tool / UVM setup  (adjust UVM_HOME to your Questa install)
# -----------------------------------------------------------------------------
UVM_HOME   = /cadtools/mentor/Questa_10.6b/questasim/verilog_src/uvm-1.1c
UVM_FLAGS  = +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv
UVM_DPI    = /cadtools/mentor/Questa_10.6b/questasim/uvm-1.1c/linux/uvm_dpi

FILELIST   = lpi.f
TOP        = tb_top
COMP_LOG   = lpi_compile.log

all:
	make clean; make compile; make simulate;

# -----------------------------------------------------------------------------
# Compile.  +acc for assertion/visibility, +cover/+fcover for coverage.
# -----------------------------------------------------------------------------
compile:
	make clean_compile;
	vlib work;
	vlog -sv \
	-L mtiUvm \
	+acc \
	+cover \
	+fcover \
	$(UVM_FLAGS) \
	-l $(COMP_LOG) \
	-f $(FILELIST)

	make compile_war_err

# Default test
ifndef test
override test = lpi_smoke_test
endif

# Default verbosity
ifndef uvm_verbosity
override uvm_verbosity = UVM_MEDIUM
endif

# Default per-test output folder = test name
ifndef test_folder
override test_folder = $(test)
endif

# -----------------------------------------------------------------------------
# Simulate.  Each test writes into its own folder so coverage UCDBs are unique
# and can be merged in regression.
# -----------------------------------------------------------------------------
simulate:
	mkdir $(test_folder)

	vsim -vopt \
	-sv_lib $(UVM_DPI) \
	work.$(TOP) \
	-voptargs=+acc=npr \
	-assertdebug \
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

	# To open the waveform:
	#   vsim -view $(test_folder)/waveform.wlf &
	# With saved signals:
	#   vsim -view $(test_folder)/waveform.wlf -do lpi_waves.do &

clean_simulate:
	rm -rf *_test*

clean_compile:
	rm -rf work/ *_compile.log transcript waveform.wlf
	rm -rf merged_coverage.ucdb merged_cov_html_report

clean:
	make clean_compile
	make clean_simulate

# -----------------------------------------------------------------------------
# Regression + coverage merge
# -----------------------------------------------------------------------------
regression:
	make clean_simulate
	python regression_handling.py $(testlist_name)
	make merge_cov_report

# Coverage names per test must be unique for the merge to work.
merge_cov_report:
	rm -rf merged_coverage.ucdb merged_cov_html_report
	vcover merge merged_coverage.ucdb -64 */*.ucdb
	vcover report -html merged_coverage.ucdb -htmldir ./merged_cov_html_report -details

	echo "";
	echo "-----------------------------------------------------------------";
	echo "Coverage report: firefox merged_cov_html_report/index.html &"
	echo "-----------------------------------------------------------------";
	echo "";

# -----------------------------------------------------------------------------
# Log scrapers
# -----------------------------------------------------------------------------
compile_war_err:
	echo "";
	echo "-----------------------------------------------------------------";
	echo "------------------- Compilation Report --------------------------";
	echo "";
	grep "^** " $(COMP_LOG);
	echo "";
	grep "^Error" $(COMP_LOG);
	echo "";
	echo "Log file path: $(COMP_LOG)"
	echo "";
	echo "-----------------------------------------------------------------";
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
	echo "Testname: $(test)"
	echo "";
	echo "Log file path: $(test_folder)/$(test).log"
	echo "";
	echo "Waveform: vsim -view $(test_folder)/waveform.wlf &"
	echo "";
	echo "Coverage report (per-test ucdb): $(test_folder)/$(test)_coverage.ucdb"
	echo "";
	echo "-----------------------------------------------------------------";
	echo "-----------------------------------------------------------------";
	echo "";
