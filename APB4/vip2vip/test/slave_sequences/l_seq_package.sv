`ifndef L_SEQ_PACKAGE
`define L_SEQ_PACKAGE
package l_seq_package;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import component_l_pkg::*;
    `include "apb_seq_base_slave.sv"
    `include "apb_seq_slave_test.sv"
		`include "apb_seq_slave_read_with_rand_wait.sv"
		`include "apb_seq_slave_write_slverr.sv"
endpackage
`endif
