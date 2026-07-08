`ifndef AXI5_VIRTUAL_BK_WRITE_READ_SEQ_INCLUDED_
`define AXI5_VIRTUAL_BK_WRITE_READ_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_virtual_bk_write_read_seq
// Creates and starts the master and slave sequences
//--------------------------------------------------------------------------------------------
class axi5_virtual_bk_write_read_seq extends axi5_virtual_base_seq;
  `uvm_object_utils(axi5_virtual_bk_write_read_seq)

  //Variable: axi5_master_write_seq_h
  //Instantiation of axi5_master_write_seq handle
  axi5_master_bk_write_seq axi5_master_bk_write_seq_h;
  
  //Variable: axi5_master_read_seq_h
  //Instantiation of axi5_master_read_seq handle
  axi5_master_bk_read_seq axi5_master_bk_read_seq_h;

  //Variable: axi5_slave_write_seq_h
  //Instantiation of axi5_slave_write_seq handle
  axi5_slave_bk_write_seq axi5_slave_bk_write_seq_h;

  //Variable: axi5_slave_read_seq_h
  //Instantiation of axi5_slave_read_seq handle
  axi5_slave_bk_read_seq axi5_slave_bk_read_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_virtual_bk_write_read_seq");
  extern task body();
endclass : axi5_virtual_bk_write_read_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initialises new memory for the object
//
// Parameters:
//  name - axi5_virtual_bk_write_read_seq
//--------------------------------------------------------------------------------------------
function axi5_virtual_bk_write_read_seq::new(string name = "axi5_virtual_bk_write_read_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task - body
// Creates and starts the data of master and slave sequences
//--------------------------------------------------------------------------------------------
task axi5_virtual_bk_write_read_seq::body();
  axi5_master_bk_write_seq_h = axi5_master_bk_write_seq::type_id::create("axi5_master_bk_write_seq_h");
  axi5_master_bk_read_seq_h = axi5_master_bk_read_seq::type_id::create("axi5_master_bk_read_seq_h");

  axi5_slave_bk_write_seq_h = axi5_slave_bk_write_seq::type_id::create("axi5_slave_bk_write_seq_h");
  axi5_slave_bk_read_seq_h = axi5_slave_bk_read_seq::type_id::create("axi5_slave_bk_read_seq_h");

  `uvm_info(get_type_name(), $sformatf("DEBUG_MSHA :: Insdie axi5_virtual_bk_write_read_seq"), UVM_NONE); 

  fork 
    begin : T1_SL_WR
      forever begin
        axi5_slave_bk_write_seq_h.start(p_sequencer.axi5_slave_write_seqr_h);
      end
    end
    begin : T2_SL_RD
      forever begin
        axi5_slave_bk_read_seq_h.start(p_sequencer.axi5_slave_read_seqr_h);
      end
    end
  join_none


  fork 
    begin: T1_WRITE
      repeat(2) begin
        axi5_master_bk_write_seq_h.start(p_sequencer.axi5_master_write_seqr_h);
      end
    end
    begin: T2_READ
      repeat(3) begin
      axi5_master_bk_read_seq_h.start(p_sequencer.axi5_master_read_seqr_h);
      end
    end
  join
 endtask : body

`endif

