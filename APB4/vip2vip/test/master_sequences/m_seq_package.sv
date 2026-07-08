`ifndef M_SEQ_PACKAGE
`define M_SEQ_PACKAGE
package m_seq_package;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import component_m_pkg::*;
    `include "apb_seq_base_master.sv"
    `include "apb_seq_master_test.sv"
		`include "apb_seq_master_read_with_rand_wait.sv"
		`include "apb_seq_master_write_slverr.sv"
endpackage
`endif
