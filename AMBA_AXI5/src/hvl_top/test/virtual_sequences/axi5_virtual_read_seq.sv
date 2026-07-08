`ifndef AXI5_VIRTUAL_READ_SEQ_INCLUDED_
`define AXI5_VIRTUAL_READ_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_virtual_read_seq
// Creates and starts the master and slave sequences
//--------------------------------------------------------------------------------------------
class axi5_virtual_read_seq extends axi5_virtual_base_seq;
  `uvm_object_utils(axi5_virtual_read_seq)

  //Variable: axi5_master_bk_read_seq_h
  //Instantiation of axi5_master_bk_read_seq handle
  axi5_master_bk_read_seq axi5_master_bk_read_seq_h;
  //Variable: axi5_master_nbk_read_seq_h
  //Instantiation of axi5_master_nbk_read_seq handle
  axi5_master_nbk_read_seq axi5_master_nbk_read_seq_h;

  //Variable: axi5_slave_read_seq_h
  //Instantiation of axi5_slave_read_seq handle
  axi5_slave_bk_read_seq axi5_slave_bk_read_seq_h;
  //Variable: axi5_slave_nbk_read_seq_h
  //Instantiation of axi5_slave_nbk_read_seq handle
  axi5_slave_nbk_read_seq axi5_slave_nbk_read_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_virtual_read_seq");
  extern task body();
endclass : axi5_virtual_read_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initialises new memory for the object
//
// Parameters:
//  name - axi5_virtual_read_seq
//--------------------------------------------------------------------------------------------
function axi5_virtual_read_seq::new(string name = "axi5_virtual_read_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task - body
// Creates and starts the data of master and slave sequences
//--------------------------------------------------------------------------------------------
task axi5_virtual_read_seq::body();
  axi5_master_bk_read_seq_h = axi5_master_bk_read_seq::type_id::create("axi5_master_bk_read_seq_h");
  axi5_master_nbk_read_seq_h = axi5_master_nbk_read_seq::type_id::create("axi5_master_nbk_read_seq_h");
  axi5_slave_bk_read_seq_h = axi5_slave_bk_read_seq::type_id::create("axi5_slave_bk_read_seq_h");
  axi5_slave_nbk_read_seq_h = axi5_slave_nbk_read_seq::type_id::create("axi5_slave_nbk_read_seq_h");
  repeat(3) begin
  fork
		begin : T1_BK
	 		axi5_slave_bk_read_seq_h.start(p_sequencer.axi5_slave_read_seqr_h);
		end
		begin : T2_BK
			 axi5_master_bk_read_seq_h.start(p_sequencer.axi5_master_read_seqr_h);
		end
	join
end
fork
		forever begin
	 		axi5_slave_nbk_read_seq_h.start(p_sequencer.axi5_slave_read_seqr_h);
		end
join_none
		repeat(5) begin
			 axi5_master_nbk_read_seq_h.start(p_sequencer.axi5_master_read_seqr_h);
		end
 endtask : body

`endif

