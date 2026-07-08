# --- Cấu hình ---
FLIST         = file_list.f
TOP_MODULE    = top
LOG_COMPILE   = uvm_compile.log

UVM_HOME  = /cadtools/mentor/Questa_10.6b/questasim/verilog_src/uvm-1.1c
# Các cờ (flags) cho UVM
UVM_FLAGS     = +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv

.IGNORE: compile simulate
.SILENT: usage compile simulate compile_report simulate_report

usage:
	echo ""
	echo "------------------------- UVM APB Master Usage -------------------------"
	echo "make compile                         : Biên dịch toàn bộ bằng file .f"
	echo "make simulate test=<name> verb=<LVL> : Chạy mô phỏng UVM"
	echo "Example: make all test=apb_read_test verb=UVM_HIGH"
	echo "------------------------------------------------------------------------"

# Mặc định verbosity là MEDIUM
ifndef verb
override verb = UVM_MEDIUM
endif

ifndef test
override test = apb_test
endif

ifndef test_folder
override test_folder = sim_$(test)
endif

# --- Targets ---

all: clean compile simulate

compile: clean_compile
	vlib work
	# Sử dụng -f để đọc danh sách file từ flist.f
	vlog -sv +acc +cover \
		$(UVM_FLAGS) \
		-l $(LOG_COMPILE) \
		-f $(FLIST)
	make compile_report

simulate:
	rm -rf $(test_folder)
	mkdir $(test_folder)
	vsim -vopt work.$(TOP_MODULE) \
		-sv_lib /cadtools/mentor/Questa_10.6b/questasim/uvm-1.1c/linux/uvm_dpi \
		-voptargs=+acc \
		+UVM_TESTNAME=$(test) \
		+UVM_VERBOSITY=$(verb) \
		-l $(test_folder)/$(test).log \
		-c -do "log -r /*; add wave -r /*; coverage save -onexit $(test_folder)/coverage.ucdb; run -all; exit" \
		-wlf $(test_folder)/waveform.wlf
	make simulate_report

# --- Báo cáo và Dọn dẹp (Giống như mẫu trước) ---
compile_report:
	echo "--- COMPILATION REPORT ---"
	grep -E "\*\* Error|\*\* Warning" $(LOG_COMPILE) || echo "Compile Clean!"

simulate_report:
	echo "--- UVM SIMULATION REPORT ---"
	grep -E "UVM_ERROR|UVM_FATAL" $(test_folder)/$(test).log || echo "UVM Test Passed!"
	echo "Log: $(test_folder)/$(test).log"

clean_compile:
	rm -rf work/ $(LOG_COMPILE) transcript

clean: clean_compile
	rm -rf sim_* merged_cov*
