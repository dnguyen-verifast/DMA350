# -s means silent mode
# The command executed along with the output will be displayed on the terminal
# To get only the ouput use 'silent' mode
#
# make target -s


# -n or --just-print
# The first test I perform on a new makefile target is to invoke make with the --just-print (-n) option.
# This causes make to read the makefile and print every command it would normally execute to
# update the target but without executing them.
#
# make target -n


# When you run make with the -i or --ignore-errors flag,
# errors are ignored in all recipes of all rules.
# A rule in the makefile for the special target .IGNORE has the same effect,
# if there are no prerequisites. This is less flexible but sometimes useful.
# When errors are to be ignored, because of -i flag, make treats an error return just like success,
# except that it prints out a message that tells you the status code the shell exited with,
# and says that the error has been ignored.
#
# make target -i

# Chay tu thu muc sim/ :
#   make compile
#   make simulate test=dma350_single_copy_test uvm_verbosity=UVM_MEDIUM
#   make regression testlist_name=dma350_regression.list
#
# LUU Y:
#  * Filelist ../../dma350.f duoc doc bang -F (duong dan ben trong .f resolve theo
#    vi tri cua CHINH file .f = goc repo DMA) -> khong can chinh path.
#  * UVM: Questa tu cung cap UVM built-in. Neu ban dung UVM rieng, mo comment
#    2 dong UVM_HOME trong target compile.
#  * BACKDOOR RAL can +acc (da co -voptargs=+acc=npr trong vsim va +acc o vlog).

export DMA350_TOP := dma350_tb_top

.IGNORE:
	compile
	simulate

# WE can also use the target where we WANT the silent mode
.SILENT:
	compile
	simulate
	usage

# First target will be executed incase the user doesn't mention
# the target to execute
# In this case, usage will be executed
# Usage
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
	echo "Example:":
	echo "make simulate test=dma350_single_copy_test uvm_verbosity=UVM_HIGH";
	echo "";
	echo "Available tests:";
	echo "  dma350_reg_access_test        dma350_single_copy_test";
	echo "  dma350_fill_test              dma350_2d_copy_test";
	echo "  dma350_wrap_test              dma350_multi_channel_test";
	echo "  dma350_stop_pause_test        dma350_allch_stop_pause_test";
	echo "  dma350_lowpower_test          dma350_gpo_test";
	echo "";
	echo "To run regression:"
	echo "make regression testlist_name=<regression_testlist_name.list>";
	echo "";
	echo "Example:":
	echo "make regression testlist_name=dma350_regression.list";
	echo "";
	echo "PASS/FAIL (dua vao UVM_ERROR + UVM_FATAL trong log):"
	echo "  make simulate test=<ten>    -> tu in ket qua test do o cuoi";
	echo "  make regression ...          -> tu in bang tong ket o cuoi";
	echo "  make check_test test=<ten>   -> chi doc lai log, khong chay sim";
	echo "  make report testlist_name=<list> -> bang tong ket, khong chay sim";
	echo "";
	echo "-----------------------------------------------------------------";
	echo "-----------------------------------------------------------------";
	echo "";

all:
	make clean_compile; make compile; make simulate;

# For Assertions use +acc options
#  +cover=becstf
compile:
	make clean_compile;
	#make clean_simulate;
	vlib work;
	vlog -sv \
	+acc \
	+cover \
	+fcover \
	-l dma350_compile.log \
	-F ../../dma350.f
	# Neu Questa khong tu tim thay UVM, dung 2 dong nay thay cho vlog o tren:
	# vlog -sv +acc +cover +fcover -l dma350_compile.log \
	#   +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv -F ../../dma350.f

	# -s means silent mode
	#  The command executed along with the output will be displayed on the terminal
	#  To get only the ouput use 'silent' mode
	# make compile_war_err -s
	# or use .SILENT
	make compile_war_err

# Setting a default test as dma350_base_test
ifndef test
override test = dma350_base_test
endif

# Setting the default uvm_verbosity to UVM_MEDIUM
ifndef uvm_verbosity
override uvm_verbosity = UVM_MEDIUM
endif



## For randomized seed
# TODO:
# Add this line after -sva
# -sv_seed random

# Setting the default test folder to test name
ifndef test_folder
override test_folder = $(test)
endif

# Setting the default wave do file (dat canh Makefile trong sim/)
ifndef wave_do
override wave_do = dma350_waves.do
endif

simulate:
	mkdir -p $(test_folder)

	# Use -novopt for no optimization - Makes the simulation slower
	# vsim -pli finesim.so -coverage top
	vsim -vopt \
	work.$(DMA350_TOP) \
	-voptargs=+acc=npr \
	-assertdebug \
	+UVM_PHASE_TRACE \
	+UVM_OBJECTION_TRACE \
	+UVM_TESTNAME=$(test) \
	+UVM_VERBOSITY=$(uvm_verbosity) \
	-l $(test_folder)/$(test).log \
	-sva \
	-coverage \
	-c -solvefaildebug -do "log -r /*; coverage save -onexit -assert -directive -cvg -codeAll $(test_folder)/$(test)_coverage.ucdb; run -all; exit" \
	-wlf $(test_folder)/waveform.wlf


	# For checking and reporting simulation errors
	make simulate_war_err
	# Ket luan PASS/FAIL cuoi cung (dua vao UVM_ERROR / UVM_FATAL trong log)
	make check_test
	# make merge_cov_report

	## For coverage report in text format
	## vcover report -text $(test_folder)/$(test)_coverage.ucdb

	# For coverage report in HTML format
	# vcover report -html $(test_folder)/$(test)_coverage.ucdb -htmldir $(test_folder)/html_cov_report -details

	# To open the html coverage report
	# firefox $(test_folder)/html_cov_report/index.html &

	# To open the waveform use the below command
	# vsim -view $(test_folder)/waveform.wlf &
	#
	# To open the wavefrom with saved signals
	# vsim -view $(test_folder)/waveform.wlf -do dma350_waves.do &

# Mo waveform da log (.wlf) + ap layout/group tu file .do.
# .wlf chi luu du lieu tin hieu; cau truc folder/group nam trong dma350_waves.do,
# chi co y nghia khi VIEW (khong luu trong .wlf, nen batch KHONG can add wave).
# Chay: make waves test=dma350_single_copy_test
waves:
	vsim -view $(test_folder)/waveform.wlf -do $(wave_do) &

##
## PASS/FAIL reporting
##
# Ket luan cho 1 test. PASS khi log co "UVM Report Summary" VA UVM_ERROR=0 VA
# UVM_FATAL=0. Chi tiet tieu chi: xem check_result.sh
#   make check_test test=dma350_single_copy_test
check_test:
	@echo "";
	@echo "-----------------------------------------------------------------";
	@echo "------------------------ TEST RESULT ----------------------------";
	@sh ./check_result.sh $(test_folder)/$(test).log $(test); \
	 rc=$$?; \
	 echo "-----------------------------------------------------------------"; \
	 echo ""; \
	 exit $$rc

# Bang tong ket PASS/FAIL cho MOI test trong testlist (khong chay lai sim).
#   make report testlist_name=dma350_regression.list
report:
	@echo "";
	@echo "=================================================================";
	@echo "===================== REGRESSION SUMMARY ========================";
	@echo "";
	@pass=0; fail=0; failed=""; \
	 for t in `grep "_test" $(testlist_name) | grep -v "^\#"`; do \
	   if sh ./check_result.sh $$t/$$t.log $$t; then \
	     pass=`expr $$pass + 1`; \
	   else \
	     fail=`expr $$fail + 1`; failed="$$failed $$t"; \
	   fi; \
	 done; \
	 total=`expr $$pass + $$fail`; \
	 echo ""; \
	 echo "  TONG: $$total | PASS: $$pass | FAIL: $$fail"; \
	 if [ $$fail -ne 0 ]; then \
	   echo ""; \
	   echo "  Test FAIL:"; \
	   for f in $$failed; do echo "    - $$f   (log: $$f/$$f.log)"; done; \
	 fi; \
	 echo "================================================================="; \
	 echo ""; \
	 [ $$fail -eq 0 ]

clean_simulate:
	rm -rf *_test*

clean_compile:
	rm -rf work/ *_compile.log transcript waveform.wlf
	rm -rf merged_coverage.ucdb merged_cov_html_report

clean:
	make clean_compile
	make clean_simulate

##
## For Regression and coverage merge
##
# Doc tung dong (bo dong # comment) trong testlist va chay make simulate.
# '|| true' de 1 test FAIL khong lam dung ca regression -> van chay het roi
# tong ket o buoc 'report'.
regression:
	for t in `grep "_test" $(testlist_name) | grep -v "^\#"`; do \
		make simulate test=$$t || true; \
	done
	# Merge coverage ('-' = bo qua loi, khong duoc chan bang tong ket ben duoi)
	-make merge_cov_report
	# Bang tong ket PASS/FAIL - hien CUOI CUNG
	make report testlist_name=$(testlist_name)

# For merge to happen, the coverage names for each test must be different
#
merge_cov_report:
	rm -rf merged_coverage.ucdb merged_cov_html_report
	# Merging all the coverage
	vcover merge merged_coverage.ucdb -64 */*.ucdb
	vcover report -html merged_coverage.ucdb -htmldir ./merged_cov_html_report -details

	echo "";
	echo "-----------------------------------------------------------------";
	echo "Coverage report: firefox merged_cov_html_report/index.html &"
	echo "-----------------------------------------------------------------";
	echo "";

compile_war_err:
	echo "";
	echo "-----------------------------------------------------------------";
	echo "------------------- Compilation Report --------------------------";
	echo "";
	grep "^\*\* Warning" dma350_compile.log || true;
	echo "";
	grep "^\*\* Error" dma350_compile.log || true;
	echo "";
	echo "Log file path: dma350_compile.log"
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
	grep "Error" $(test_folder)/$(test).log || true;
	echo "";
	echo "UVM Fatal";
	grep "UVM_FATAL" $(test_folder)/$(test).log || true;
	echo "";
	echo "UVM Errors";
	grep "UVM_ERROR" $(test_folder)/$(test).log || true;
	echo "";
	echo "UVM Warnings";
	grep "UVM_WARNING" $(test_folder)/$(test).log || true;
	echo "";
	echo "Testname: $(test)"
	echo "";
	echo "Log file path: $(test_folder)/$(test).log"
	echo "";
	echo "Waveform: vsim -view $(test_folder)/waveform.wlf &"
	echo "";
	echo "Coverage report: firefox $(test_folder)/html_cov_report/index.html &"
	echo "";
	echo "-----------------------------------------------------------------";
	echo "-----------------------------------------------------------------";
	echo "";
