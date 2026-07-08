`ifndef AXI5_VIRTUAL_NBK_UNALIGNED_ADDR_WRITE_READ_SEQ_INCLUDED_
`define AXI5_VIRTUAL_NBK_UNALIGNED_ADDR_WRITE_READ_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_virtual_nbk_unaligned_addr_write_read_seq
// Creates and starts the master and slave sequences
//--------------------------------------------------------------------------------------------
class axi5_virtual_nbk_unaligned_addr_write_read_seq extends axi5_virtual_base_seq;
  `uvm_object_utils(axi5_virtual_nbk_unaligned_addr_write_read_seq)

  //Variable: axi5_master_write_unaligned_addr_seq_h
  //Instantiation of axi5_master_write_unaligned_addr_seq handle
  axi5_master_nbk_write_unaligned_addr_seq axi5_master_nbk_write_unaligned_addr_seq_h;
  
  //Variable: axi5_master_read_unaligned_addr_seq_h
  //Instantiation of axi5_master_read_unaligned_addr_seq handle
  axi5_master_nbk_read_unaligned_addr_seq axi5_master_nbk_read_unaligned_addr_seq_h;

  //Variable: axi5_slave_write_unaligned_addr_seq_h
  //Instantiation of axi5_slave_write_unaligned_addr_seq handle
  axi5_slave_nbk_write_unaligned_addr_seq axi5_slave_nbk_write_unaligned_addr_seq_h;
  
  //Variable: axi5_slave_read_unaligned_addr_seq_h
  //Instantiation of axi5_slave_read_unaligned_addr_seq handle
  axi5_slave_nbk_read_unaligned_addr_seq axi5_slave_nbk_read_unaligned_addr_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_virtual_nbk_unaligned_addr_write_read_seq");
  extern task body();
endclass : axi5_virtual_nbk_unaligned_addr_write_read_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initialises new memory for the object
//
// Parameters:
//  name - axi5_virtual_nbk_maximum_write_read_seq
//--------------------------------------------------------------------------------------------
function axi5_virtual_nbk_unaligned_addr_write_read_seq::new(string name = "axi5_virtual_nbk_unaligned_addr_write_read_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task - body
// Creates and starts the data of master and slave sequences
//--------------------------------------------------------------------------------------------
task axi5_virtual_nbk_unaligned_addr_write_read_seq::body();
  queue_info_ctrl_s queue_info_ctrl_h, queue_info_ctrl_h1;
  axi5_master_nbk_write_unaligned_addr_seq_h = axi5_master_nbk_write_unaligned_addr_seq::type_id::create("axi5_master_nbk_write_unaligned_addr_seq_h");

  axi5_master_nbk_read_unaligned_addr_seq_h = axi5_master_nbk_read_unaligned_addr_seq::type_id::create("axi5_master_nbk_read_unaligned_addr_seq_h");
  axi5_slave_nbk_write_unaligned_addr_seq_h = axi5_slave_nbk_write_unaligned_addr_seq::type_id::create("axi5_slave_nbk_write_unaligned_addr_seq_h");

  axi5_slave_nbk_read_unaligned_addr_seq_h = axi5_slave_nbk_read_unaligned_addr_seq::type_id::create("axi5_slave_nbk_read_unaligned_addr_seq_h");
  `uvm_info(get_type_name(), $sformatf("DEBUG_MSHA :: Inside axi5_virtual_nbk_unaligned_addr_write_read_seq"), UVM_NONE); 

  fork 
    begin : T1_SL_WR
      forever begin
        axi5_slave_nbk_write_unaligned_addr_seq_h.start(p_sequencer.axi5_slave_write_seqr_h);
      end
    end
    begin : T2_SL_RD
      forever begin
        axi5_slave_nbk_read_unaligned_addr_seq_h.start(p_sequencer.axi5_slave_read_seqr_h);
      end
    end
  join_none


  fork 
    begin: T1_WRITE
      repeat(5) begin
        axi5_master_nbk_write_unaligned_addr_seq_h.start(p_sequencer.axi5_master_write_seqr_h);
        queue_info_ctrl_h.addr = axi5_master_nbk_write_unaligned_addr_seq_h.req.awaddr;
        queue_info_ctrl_h.id = axi5_master_nbk_write_unaligned_addr_seq_h.req.awid;
        p_sequencer.queue_info_ctrl.push_back(queue_info_ctrl_h);
      end
    end
    begin: T2_READ
      repeat(5) begin
        wait(p_sequencer.queue_info_ctrl.size() > 0); 
        queue_info_ctrl_h1 = p_sequencer.queue_info_ctrl.pop_front();
        axi5_master_nbk_read_unaligned_addr_seq_h.queue_info_ctrl_r.addr = queue_info_ctrl_h1.addr;
        axi5_master_nbk_read_unaligned_addr_seq_h.queue_info_ctrl_r.id = queue_info_ctrl_h1.id;
        axi5_master_nbk_read_unaligned_addr_seq_h.start(p_sequencer.axi5_master_read_seqr_h);
      end
    end
  join
 endtask : body

`endif

