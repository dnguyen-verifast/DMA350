all:
				make clean; make sim;

VCS_CMD_RAND    = vcs -V -R  -full64 -sverilog +v2k -debug_access+all -ntb_opts uvm-1.2 -debug_pp +ntb_random_seed_automatic -override_timescale=1ps/1ps

sim:
				${VCS_CMD_RAND} \
        +incdir+../../src/globals/ \
        +incdir+../../src/verif/vip/axi_master_vip/ \
        +incdir+../../src/verif/vip/axi_slave_vip/ \
        +incdir+../../src/verif/bfm/read_fifo/ \
        +incdir+../../src/verif/bfm/write_fifo/ \
        +incdir+../../src/verif/bfm/write_fifo/fifo_interface \
        +incdir+../../src/verif/tb/env/ \
        +incdir+../../src/verif/tb/test/  \
        +incdir+../../src/hdl_top/ \
        +incdir+../../src/hdl_top/axi5_interface/ \
        +incdir+../../src/hdl_top/master_agent_bfm/ \
        +incdir+../../src/hdl_top/slave_agent_bfm/ \
        +incdir+../../src/hvl_top/ \
        +incdir+../../src/hvl_top/env/ \
        +incdir+../../src/hvl_top/master/ \
        +incdir+../../src/hvl_top/slave/ \
        +incdir+../../src/hvl_top/test/ \
        +incdir+../../src/hvl_top/testlists/ \
        +incdir+../../src/hvl_top/env/virtual_sequencer/ \
        +incdir+../../src/hvl_top/test/sequences/ \
        +incdir+../../src/hvl_top/test/sequences/master_sequences/ \
        +incdir+../../src/hvl_top/test/sequences/slave_sequences/ \
        +incdir+../../src/hvl_top/test/virtual_sequences/ \
        +incdir+../../src/hdl_top/axi5_interface/ \
        ../../src/globals/axi5_globals_pkg.sv \
        ../../src/hvl_top/master/axi5_master_pkg.sv \
        ../../src/hvl_top/slave/axi5_slave_pkg.sv \
        ../../src/hvl_top/env/axi5_env_pkg.sv \
        ../../src/hdl_top/axi5_interface/axi5_if.sv \
        ../../src/hdl_top/master_agent_bfm/axi5_master_driver_bfm.sv \
        ../../src/hdl_top/master_agent_bfm/axi5_master_monitor_bfm.sv \
        ../../src/hdl_top/master_agent_bfm/axi5_master_agent_bfm.sv \
        ../../src/hdl_top/slave_agent_bfm/axi5_slave_driver_bfm.sv \
        ../../src/hdl_top/slave_agent_bfm/axi5_slave_monitor_bfm.sv \
        ../../src/hdl_top/slave_agent_bfm/axi5_slave_agent_bfm.sv \
        ../../src/verif/bfm/write_fifo/fifo_interface/fifo_interface.sv \
        ../../src/hvl_top/test/sequences/master_sequences/axi5_master_seq_pkg.sv \
        ../../src/hvl_top/test/sequences/slave_sequences/axi5_slave_seq_pkg.sv \
        ../../src/hvl_top/test/virtual_sequences/axi5_virtual_seq_pkg.sv \
        ../../src/hvl_top/test/axi5_test_pkg.sv \
        ../../src/verif/tb/top.sv \
        +UVM_VERBOSITY=MEDIUM \
        +plusarg_ignore \
        -l transcript_vcs.log

        #+incdir+/projects/UVM/uvm-1.2/src \
        #/projects/UVM/uvm-1.2/src/uvm_pkg.sv \

        #vsim -novopt work.hvl_top work.hdl_top -c -do "log -r /*; add wave -r /*; run -all;" \
        #-wlf waveform.wlf
        # To open the waveform use the below command 
        # vsim -view waveform.wlf &

clean:
				rm -rf work/ transcript waveform.wlf

