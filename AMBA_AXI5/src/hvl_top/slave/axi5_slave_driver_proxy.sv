`ifndef AXI5_SLAVE_DRIVER_PROXY_INCLUDED_
`define AXI5_SLAVE_DRIVER_PROXY_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_slave_driver_proxy
// This is the proxy driver on the HVL side
// It receives the transactions and converts them to task calls for the HDL driver
//--------------------------------------------------------------------------------------------
class axi5_slave_driver_proxy extends uvm_driver#(axi5_slave_tx);
  `uvm_component_utils(axi5_slave_driver_proxy)

  // Port: seq_item_port
  // Derived driver classes should use this port to request items from the sequencer
  // They may also use it to send responses back.
  uvm_seq_item_pull_port #(REQ, RSP) axi_write_seq_item_port;
  uvm_seq_item_pull_port #(REQ, RSP) axi_read_seq_item_port;

  // Port: rsp_port
  // This port provides an alternate way of sending responses back to the originating sequencer.
  // Which port to use depends on which export the sequencer provides for connection.
  uvm_analysis_port #(RSP) axi_write_rsp_port;
  uvm_analysis_port #(RSP) axi_read_rsp_port;
  
  REQ req_wr, req_rd;
  RSP rsp_wr, rsp_rd;

  // Variable: axi5_slave_agent_cfg_h
  // Declaring handle for axi5_slave agent config class 
  axi5_slave_agent_config axi5_slave_agent_cfg_h;

  // Variable: axi5_slave_mem_h
  // Declaring handle for axi5_slave memory config class 
  axi5_slave_memory axi5_slave_mem_h;

  //Variable : axi5_slave_drv_bfm_h
  //Declaring handle for axi5 driver bfm
  virtual axi5_slave_driver_bfm axi5_slave_drv_bfm_h;

  //Declaring handle for uvm_tlm_analysis_fifo's for all the five channels
  uvm_tlm_fifo #(axi5_slave_tx) axi5_slave_write_addr_fifo_h;
  uvm_tlm_fifo #(axi5_slave_tx) axi5_slave_write_data_in_fifo_h;
  uvm_tlm_fifo #(axi5_slave_tx) axi5_slave_write_response_fifo_h;
  uvm_tlm_fifo #(axi5_slave_tx) axi5_slave_write_data_out_fifo_h;
  uvm_tlm_fifo #(axi5_slave_tx) axi5_slave_read_addr_fifo_h;
  uvm_tlm_fifo #(axi5_slave_tx) axi5_slave_read_data_in_fifo_h;

  //Declaring Semaphore handles for writes and reads
  semaphore semaphore_write_key;
  semaphore semaphore_rsp_write_key;
  semaphore semaphore_read_key;

  //write_read_mode_h used to get the transfer type
  write_read_data_mode_e write_read_mode_h;

  bit[3:0] wr_addr_cnt;
  bit[3:0] wr_resp_cnt;

  // Variables used for out of order support
  bit[3:0] response_id_queue[$];
  bit[3:0] response_id_cont_queue[$];

  axi5_slave_tx associate_queue_OoO_AW [bit[3:0]] [$];
  axi5_slave_tx associate_queue_OoO_W [bit[3:0]] [$];
  bit [3:0]     id_aw_chanel [$];
  bit [3:0]     active_ids_q [$];
  bit [3:0]     aw_to_w_id;
  int           random_index;
  bit [3:0]     chosen_id;
  int           recieved_data_count=0;
  bit           flag_to_read = 0;


  bit      drive_id_cont;
  bit      drive_rd_id_cont;
  axi5_read_transfer_char_s rd_response_id_queue[$];
  axi5_read_transfer_char_s rd_response_id_cont_queue[$];
 

  bit [3:0] pending_write_addr [bit [ADDRESS_WIDTH -1:0]];
  bit [3:0] memory_write_count [bit [ADDRESS_WIDTH -1:0]];
  event write_complete_event ;
  event read_complete_event ;

  bit      completed_initial_txn;
  int      crossed_read_addr=0;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_slave_driver_proxy", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task axi5_write_task();
  extern virtual task axi5_read_task();
  extern virtual task task_memory_write(inout axi5_slave_tx struct_write_packet);
  extern virtual task task_memory_read(input axi5_slave_tx read_pkt,output axi5_read_transfer_char_s struct_read_packet);
  extern virtual task out_of_order_for_reads(output axi5_read_transfer_char_s oor_read_data_struct_read_packet);
  //extern virtual task arbiter_for_out_of_order_responses();
endclass : axi5_slave_driver_proxy

//--------------------------------------------------------------------------------------------
// Construct: new
// Parameters:
//  name - axi5_slave_driver_proxy
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi5_slave_driver_proxy::new(string name = "axi5_slave_driver_proxy",
                                      uvm_component parent = null);
  super.new(name, parent);
  axi_write_seq_item_port                   = new("axi_write_seq_item_port", this);
  axi_read_seq_item_port                    = new("axi_read_seq_item_port", this);
  axi_write_rsp_port                        = new("axi_write_rsp_port", this);
  axi_read_rsp_port                         = new("axi_read_rsp_port", this);
  axi5_slave_write_addr_fifo_h              = new("axi5_slave_write_addr_fifo_h",this,16);
  axi5_slave_write_data_in_fifo_h           = new("axi5_slave_write_data_in_fifo_h",this,16);
  axi5_slave_write_response_fifo_h          = new("axi5_slave_write_response_fifo_h",this,16);
  axi5_slave_write_data_out_fifo_h          = new("axi5_slave_write_data_out_fifo_h",this,16);
  axi5_slave_read_addr_fifo_h               = new("axi5_slave_read_addr_fifo_h",this,16);
  axi5_slave_read_data_in_fifo_h            = new("axi5_slave_read_data_in_fifo_h",this,16);
  semaphore_write_key                       = new(1);
  semaphore_rsp_write_key                   = new(1);
  semaphore_read_key                        = new(1);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_slave_driver_proxy::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db #(virtual axi5_slave_driver_bfm)::get(this,"","axi5_slave_driver_bfm",axi5_slave_drv_bfm_h)) begin
    `uvm_fatal("FATAL_MDP_CANNOT_GET_tx_DRIVER_BFM","cannot get() axi5_slave_drv_bfm_h");
  end
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_slave_driver_proxy::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  if(axi5_slave_agent_cfg_h.read_data_mode == SLAVE_MEM_MODE) begin
    axi5_slave_mem_h = axi5_slave_memory::type_id::create("axi5_slave_mem_h");
		axi5_slave_mem_h.init_memory_cfg();
  end
  axi5_slave_drv_bfm_h.axi5_slave_drv_proxy_h= this;
endfunction  : end_of_elaboration_phase


//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi5_slave_driver_proxy::run_phase(uvm_phase phase);

  `uvm_info(get_type_name(),"SLAVE_DRIVER_PROXY",UVM_MEDIUM)

  //wait for system reset
  axi5_slave_drv_bfm_h.wait_for_system_reset();

  fork 
    axi5_write_task();
    axi5_read_task();
  join


endtask : run_phase 

//--------------------------------------------------------------------------------------------
// task axi5 write task
//--------------------------------------------------------------------------------------------
task axi5_slave_driver_proxy::axi5_write_task();
  
  forever begin
    
    process addr_tx;
    process data_tx;
    process response_tx;

    axi_write_seq_item_port.get_next_item(req_wr);
    // associate for read and write crossing address

    // writting the req into write data and response fifo's
    axi5_slave_write_data_in_fifo_h.put(req_wr);
    axi5_slave_write_response_fifo_h.put(req_wr);
    
    fork
    begin : WRITE_ADDRESS_CHANNEL
      
      axi5_slave_tx              local_slave_addr_tx;
      axi5_write_transfer_char_s struct_write_packet;
      axi5_transfer_cfg_s        struct_cfg;
    
      //returns status of address thread
      addr_tx=process::self();
      

      //Converting transactions into struct data type
      axi5_slave_seq_item_converter::from_write_class(req_wr,struct_write_packet);
      
      `uvm_info(get_type_name(), $sformatf("from_write_class:: struct_write_packet = \n %0p",struct_write_packet), UVM_HIGH); 

     //Converting configurations into struct config type
     axi5_slave_cfg_converter::from_class(axi5_slave_agent_cfg_h,struct_cfg);
     `uvm_info(get_type_name(), $sformatf("from_write_class:: struct_cfg =  \n %0p",struct_cfg),UVM_LOW);
     
     //write address_task
     axi5_slave_drv_bfm_h.axi5_write_address_phase(struct_write_packet);

     axi5_slave_seq_item_converter::to_write_class(struct_write_packet,local_slave_addr_tx);

     if(!pending_write_addr.exists(local_slave_addr_tx.awaddr)) begin
        pending_write_addr[local_slave_addr_tx.awaddr] = 1;
        memory_write_count[local_slave_addr_tx.awaddr] = 0;
      end else begin 
        pending_write_addr[local_slave_addr_tx.awaddr] ++ ; 
      end

     if(axi5_slave_agent_cfg_h.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER || axi5_slave_agent_cfg_h.slave_response_mode == ONLY_WRITE_RESP_OUT_OF_ORDER) begin
        id_aw_chanel.push_back(struct_write_packet.awid);
        if(associate_queue_OoO_AW.exists(struct_write_packet.awid)) begin
          `uvm_info("OUT_OF_ORDER",$sformatf("Detected a same id = %d",struct_write_packet.awid),UVM_LOW);
        end
        associate_queue_OoO_AW[struct_write_packet.awid].push_back(local_slave_addr_tx);
     end else begin
      if(axi5_slave_write_addr_fifo_h.is_full) begin
        `uvm_error(get_type_name(),$sformatf("WRITE_ADDR_THREAD::Cannot put into FIFO as WRITE_FIFO is FULL"));
      end else begin
       axi5_slave_write_addr_fifo_h.put(local_slave_addr_tx);
      end
     end
		//`uvm_info("DEBUG_QUEUE_ID",$sformatf("response id queue: %p",response_id_queue),UVM_LOW);
     //Converting struct into transaction data type
     `uvm_info("DEBUG_SLAVE_WRITE_ADDR_PROXY", $sformatf("AFTER :: Received req packet \n %s",local_slave_addr_tx.sprint()), UVM_NONE);
   end
 
  begin : WRITE_DATA_CHANNEL

      axi5_slave_tx              local_slave_data_tx;
      axi5_write_transfer_char_s struct_write_packet;
      axi5_transfer_cfg_s        struct_cfg;
      
      //returns status of write data thread
      data_tx=process::self();

      // Trying to get the write key 
      semaphore_write_key.get(1);

      //getting the data from write data fifo
      axi5_slave_write_data_in_fifo_h.get(local_slave_data_tx);
      
      //Converting transactions into struct data type
      axi5_slave_seq_item_converter::from_write_class(local_slave_data_tx,struct_write_packet);
      `uvm_info(get_type_name(), $sformatf("from_write_class:: struct_write_packet = \n %0p",struct_write_packet), UVM_HIGH); 

      //Converting configurations into struct config type
      axi5_slave_cfg_converter::from_class(axi5_slave_agent_cfg_h,struct_cfg);
      `uvm_info(get_type_name(), $sformatf("from_write_class:: struct_cfg =  \n %0p",struct_cfg),UVM_HIGH);

      // write data_task
      axi5_slave_drv_bfm_h.axi5_write_data_phase(struct_write_packet,struct_cfg);
      `uvm_info("DEBUG_SLAVE_WDATA_PROXY", $sformatf("AFTER :: Reciving struct pkt from bfm \n%p",struct_write_packet), UVM_HIGH);
     
      
      //Converting struct into transaction data type
      axi5_slave_seq_item_converter::to_write_class(struct_write_packet,local_slave_data_tx);


     `uvm_info("DEBUG_SLAVE_WDATA_PROXY_TO_CLASS", $sformatf("AFTER TO CLASS :: Received req packet \n %s", local_slave_data_tx.sprint()), UVM_NONE);

     //putting the write data into write data out fifo
     aw_to_w_id = id_aw_chanel.pop_front();
     active_ids_q.push_back(aw_to_w_id);
     if(axi5_slave_agent_cfg_h.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER || axi5_slave_agent_cfg_h.slave_response_mode == ONLY_WRITE_RESP_OUT_OF_ORDER) begin
        if(associate_queue_OoO_W.exists(aw_to_w_id)) begin
          `uvm_info("OUT_OF_ORDER",$sformatf("Detected a same id = %d",struct_write_packet.awid),UVM_LOW);
        end
        associate_queue_OoO_W[aw_to_w_id].push_back(local_slave_data_tx);
        recieved_data_count ++ ;
     end else begin 
        axi5_slave_write_data_out_fifo_h.put(local_slave_data_tx); 
      end
    
      //putting back the semaphore key
      semaphore_write_key.put(1);
    
    end
  
  begin : WRITE_RESPONSE_CHANNEL

    axi5_slave_tx              local_slave_addr_tx;
    axi5_slave_tx              local_slave_data_tx;
    axi5_slave_tx              local_slave_response_tx;
    axi5_slave_tx              packet;
    axi5_write_transfer_char_s struct_write_packet;
    axi5_transfer_cfg_s        struct_cfg;
    bit[3:0]                   bid_rsp;
    bit[3:0]                   local_awid;
    int                        end_wrap_addr;
    int                        slave_err;
    bit                        violation_addr;   
    int                        min_addr;

      //returns status of response thread
    response_tx=process::self();

    semaphore_rsp_write_key.get(1);
		
     // axi5_slave_write_data_out_fifo_h.peek(local_slave_data_tx);
   //   wait(axi5_slave_write_data_out_fifo_h.used()>0);
   `uvm_info("SLAVE_AGENT",$sformatf("Waiting for write_data_chanel finish"),UVM_LOW);
		wait(data_tx != null);
    data_tx.await();
    `uvm_info("SLAVE_AGENT",$sformatf("Move on write_response_chanel finish"),UVM_LOW);
      //getting the data from response fifo
    axi5_slave_write_response_fifo_h.get(local_slave_response_tx);
      //Converting transactions into struct data type
    `uvm_info(get_type_name(), $sformatf("from_write_class:: struct_write_packet = \n %0p",struct_write_packet), UVM_HIGH); 

      //Converting configurations into struct config type
    axi5_slave_cfg_converter::from_class(axi5_slave_agent_cfg_h,struct_cfg);
    `uvm_info(get_type_name(), $sformatf("from_write_class:: struct_cfg =  \n %0p",struct_cfg),UVM_HIGH);
    `uvm_info("slave_driver_proxy",$sformatf("min_tx=%0d",axi5_slave_agent_cfg_h.get_minimum_transactions),UVM_HIGH)

    // resolving the out of order response for write channel
    if(axi5_slave_agent_cfg_h.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER || axi5_slave_agent_cfg_h.slave_response_mode == ONLY_WRITE_RESP_OUT_OF_ORDER) begin
      `uvm_info("SLAVE_AGENT",$sformatf("Inside response OUT_OF_ORDER"),UVM_LOW);
      // if(flag_to_read == 0) begin
      //   wait(recieved_data_count >= axi5_slave_agent_cfg_h.get_minimum_transactions);
      //   flag_to_read = 1;
      // end
      if(recieved_data_count >= axi5_slave_agent_cfg_h.get_minimum_transactions) begin
        #100ns;
      end
      if(recieved_data_count >= axi5_slave_agent_cfg_h.get_minimum_transactions) begin
        random_index = $urandom_range(0, active_ids_q.size() - 1);
        chosen_id = active_ids_q[random_index];
        active_ids_q.delete(random_index);
      end else begin
        chosen_id = active_ids_q.pop_front();
      end
      local_slave_addr_tx = associate_queue_OoO_AW[chosen_id].pop_front();
      local_slave_data_tx = associate_queue_OoO_W[chosen_id].pop_front();
      recieved_data_count -- ;
    end else begin 
      `uvm_info("SLAVE_AGENT",$sformatf("Inside response IN_ORDER"),UVM_LOW);
       //check for fifo empty if not get the data 
      if(axi5_slave_write_addr_fifo_h.is_empty) begin
        `uvm_error(get_type_name(),$sformatf("WRITE_RESP_THREAD::Cannot get write addr data from FIFO as WRITE_ADDR_FIFO is EMPTY"));
      end
      else begin
        axi5_slave_write_addr_fifo_h.get(local_slave_addr_tx);
        `uvm_info("DEBUG_FIFO",$sformatf("fifo_size = %0d",axi5_slave_write_addr_fifo_h.size()),UVM_HIGH)
        `uvm_info("DEBUG_FIFO",$sformatf("fifo_used =%0d",axi5_slave_write_addr_fifo_h.used()),UVM_NONE)
      end
       axi5_slave_write_data_out_fifo_h.get(local_slave_data_tx);
    end
    //take id value
    bid_rsp = local_slave_addr_tx.awid;
    // finish the out of order response for write channel

    // compute the end address based on the burst type
    if(local_slave_addr_tx.awburst == WRITE_FIXED) begin
      end_wrap_addr =  local_slave_addr_tx.awaddr + ((2**local_slave_addr_tx.awsize));
    end
    if(local_slave_addr_tx.awburst == WRITE_INCR) begin
      end_wrap_addr =  local_slave_addr_tx.awaddr + ((local_slave_addr_tx.awlen+1)*(2**local_slave_addr_tx.awsize));
      if(end_wrap_addr[31:12] != local_slave_addr_tx.awaddr[31:12]) begin
        violation_addr = 1;
        `uvm_info("SLAVE_AGENT",$sformatf("Address wrap around detected. Marking as error"),UVM_LOW);
      end else begin
        violation_addr = 0;
      end
    end
    if(local_slave_addr_tx.awburst == WRITE_WRAP) begin
       end_wrap_addr = local_slave_addr_tx.awaddr - int'(local_slave_addr_tx.awaddr%((local_slave_addr_tx.awlen+1)*(2**local_slave_addr_tx.awsize)));
       min_addr = local_slave_addr_tx.awaddr - int'(local_slave_addr_tx.awaddr%((local_slave_addr_tx.awlen+1)*(2**local_slave_addr_tx.awsize)));
       end_wrap_addr = end_wrap_addr + ((local_slave_addr_tx.awlen+1)*(2**local_slave_addr_tx.awsize));
      if(min_addr[31:12] != local_slave_addr_tx.awaddr[31:12]) begin
        violation_addr = 1;
        `uvm_info("SLAVE_AGENT",$sformatf("Address wrap around detected. Marking as error"),UVM_LOW);
      end else begin
        violation_addr = 0;
      end
    end
    // finish to compute the end address based on the burst type

		`uvm_info("SLAVE_AGENT",$sformatf("read_data_mode = %s",axi5_slave_agent_cfg_h.read_data_mode),UVM_LOW);
    `uvm_info("get_type_name",$sformatf("end_addr=%0h",end_wrap_addr),UVM_HIGH);

    // using the check_access_permission function to check the access permission for the write address and setting the write response accordingly
    if(axi5_slave_agent_cfg_h.read_data_mode == SLAVE_MEM_MODE || axi5_slave_agent_cfg_h.read_data_mode == SLAVE_ERR_RESP_MODE) begin
      slave_err = axi5_slave_mem_h.check_access_permission(local_slave_addr_tx.awaddr, 
                                                      region_e'(local_slave_addr_tx.awregion), 
                                                      prot_e'(local_slave_addr_tx.awprot), 
                                                      lock_e'(local_slave_addr_tx.awlock), 1'b1);
      local_slave_addr_tx.bresp = (slave_err == 2)? WRITE_SLVERR 
                                        : ((violation_addr == 1)? ((local_slave_addr_tx.awlock == WRITE_NORMAL_ACCESS)? WRITE_OKAY : WRITE_EXOKAY) 
                                          : (local_slave_addr_tx.awlock == WRITE_NORMAL_ACCESS)? WRITE_EXOKAY : WRITE_OKAY);
      // write response_task
      local_slave_response_tx.bresp = local_slave_addr_tx.bresp;
      `uvm_info("DEBUG_SLAVE_WDATA_PROXY", $sformatf("AFTER :: Reciving struct pkt from bfm \n %p",struct_write_packet), UVM_HIGH);
    end

    axi5_slave_seq_item_converter::from_write_class(local_slave_response_tx,struct_write_packet);
    axi5_slave_drv_bfm_h.axi5_write_response_phase(struct_write_packet,struct_cfg,bid_rsp);
      //Converting struct into transaction data type
    axi5_slave_seq_item_converter::to_write_class(struct_write_packet,local_slave_response_tx);

    `uvm_info("DEBUG_SLAVE_WDATA_PROXY_TO_CLASS", $sformatf("AFTER TO CLASS :: Received req packet \n %s", local_slave_response_tx.sprint()), UVM_NONE);
  
    //Calling combined data packet from converter class
    axi5_slave_seq_item_converter::tx_write_packet(local_slave_addr_tx,local_slave_data_tx,local_slave_response_tx,packet);
    `uvm_info("DEBUG_SLAVE_WDATA_PROXY", $sformatf("AFTER :: COMBINED WRITE CHANNEL PACKET \n%s",packet.sprint()), UVM_NONE);

    //calling task memory write to store the data into slave memory
    if(axi5_slave_agent_cfg_h.read_data_mode == SLAVE_MEM_MODE && ((local_slave_addr_tx.awlock == WRITE_NORMAL_ACCESS && local_slave_response_tx.bresp == WRITE_OKAY) ||
                                                                   (local_slave_addr_tx.awlock == WRITE_EXCLUSIVE_ACCESS && local_slave_response_tx.bresp == WRITE_EXOKAY))) begin
      task_memory_write(packet);
    end

    if(pending_write_addr.exists(local_slave_addr_tx.awaddr) && pending_write_addr[local_slave_addr_tx.awaddr] > 0) begin
      pending_write_addr[local_slave_addr_tx.awaddr] -- ;
      memory_write_count[local_slave_addr_tx.awaddr] ++ ;   
    end
    -> write_complete_event;
    semaphore_rsp_write_key.put(1);
  end

  join_any

  //checking the status of write address thread
  addr_tx.await();
  `uvm_info("SLAVE_STATUS_CHECK",$sformatf("AFTER_FORK_JOIN_ANY:: SLAVE_ADDRESS_CHANNEL_STATUS =\n %s",addr_tx.status()),UVM_MEDIUM)
  `uvm_info("SLAVE_STATUS_CHECK",$sformatf("AFTER_FORK_JOIN_ANY:: SLAVE_WDATA_CHANNEL_STATUS = \n %s",data_tx.status()),UVM_MEDIUM)
  `uvm_info("SLAVE_STATUS_CHECK",$sformatf("AFTER_FORK_JOIN_ANY:: SLAVE_WRESP_CHANNEL_STATUS = \n%s",response_tx.status()),UVM_MEDIUM)
   
   axi_write_seq_item_port.item_done();

 end
 
 endtask : axi5_write_task

//-------------------------------------------------------
// task axi5 read task
//-------------------------------------------------------
task axi5_slave_driver_proxy::axi5_read_task();
  
  forever begin
    
    //Declaring the process for read address channel and read data channel for status check 
    process rd_addr;
    process rd_data;

    axi_read_seq_item_port.get_next_item(req_rd);
    

    //putting the data into read data fifo
    axi5_slave_read_data_in_fifo_h.put(req_rd);

    fork
      begin : READ_ADDRESS_CHANNEL
        
        axi5_slave_tx              local_slave_tx;
        axi5_read_transfer_char_s struct_read_packet;
        axi5_read_transfer_char_s oor_struct_read_packet;
        axi5_transfer_cfg_s       struct_cfg;
        
        //returns status of address thread
        rd_addr = process::self();
        
        //Converting transactions into struct data type
        axi5_slave_seq_item_converter::from_read_class(req_rd,struct_read_packet);
        `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_read_packet = \n %0p",struct_read_packet), UVM_HIGH); 
        
        //Converting configurations into struct config type
        axi5_slave_cfg_converter::from_class(axi5_slave_agent_cfg_h,struct_cfg);
        `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_cfg =  \n %0p",struct_cfg),UVM_LOW);
        
        //read address_task
        axi5_slave_drv_bfm_h.axi5_read_address_phase(struct_read_packet,struct_cfg);

      // Storing data for enabling out_of_order feature
      if(axi5_slave_agent_cfg_h.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER || axi5_slave_agent_cfg_h.slave_response_mode == ONLY_READ_RESP_OUT_OF_ORDER) begin
        if(rd_response_id_queue.size() == 0) begin
          rd_response_id_queue.push_back(struct_read_packet);
        end
        else begin
          // condition to check if the same id's are coming back to back
          oor_struct_read_packet = rd_response_id_queue[$];
          if(struct_read_packet.arid == oor_struct_read_packet.arid) begin
            drive_rd_id_cont = 1'b1;
            oor_struct_read_packet = rd_response_id_queue.pop_back();
            rd_response_id_cont_queue.push_back(oor_struct_read_packet);
            rd_response_id_cont_queue.push_back(struct_read_packet);
          end
          else begin 
            rd_response_id_queue.push_back(struct_read_packet);
          end
        end
      end
        
      //Converting struct into transaction data type
      axi5_slave_seq_item_converter::to_read_class(struct_read_packet,local_slave_tx);
      `uvm_info("DEBUG_SLAVE_READ_ADDR_PROXY", $sformatf(" to_class_raddr_phase_slave_proxy  \n %p",struct_read_packet), UVM_NONE);
      
      //Putting back the sampled read address data into fifo
      axi5_slave_read_addr_fifo_h.put(local_slave_tx);
      `uvm_info("DEBUG_SLAVE_READ_ADDR_PROXY", $sformatf("AFTER :: Received req packet \n %s",local_slave_tx.sprint()), UVM_NONE);
      
    end
    
    begin : READ_DATA_CHANNEL
      
      axi5_slave_tx              local_slave_rdata_tx;
      axi5_slave_tx              local_slave_raddr_tx;
      axi5_slave_tx              local_slave_addr_chk_tx;
      axi5_slave_tx              packet;
      axi5_read_transfer_char_s struct_read_packet;
      axi5_transfer_cfg_s       struct_cfg;
      int                       total_bytes;

      //returns status of data thread
      rd_data = process::self();

      //Waiting for the read address thread to complete
      rd_addr.await();

      //Getting the data from read data fifo
      axi5_slave_read_data_in_fifo_h.get(local_slave_rdata_tx);
      axi5_slave_read_addr_fifo_h.peek(local_slave_addr_chk_tx);

      if(axi5_slave_agent_cfg_h.read_data_mode == RANDOM_DATA_MODE || write_read_mode_h == ONLY_READ_DATA) begin
        
        //Getting the key from semaphore
        semaphore_read_key.get(1);

        //Converting transactions into struct data type
        axi5_slave_seq_item_converter::from_read_class(local_slave_rdata_tx,struct_read_packet);
        `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_read_packet = \n %0p",struct_read_packet), UVM_HIGH); 
  
        //Converting configurations into struct config type
        axi5_slave_cfg_converter::from_class(axi5_slave_agent_cfg_h,struct_cfg);
        `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_cfg =  \n %0p",struct_cfg),UVM_HIGH);
        
        //Task to check the out_of_order enable and updates the read structure 
        if((axi5_slave_agent_cfg_h.slave_response_mode == ONLY_READ_RESP_OUT_OF_ORDER) || (axi5_slave_agent_cfg_h.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER) ) begin
          out_of_order_for_reads(struct_read_packet);
          `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_read_packet = \n %0p",struct_read_packet), UVM_NONE); 
        end
        
        `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("BEFORE :: READ CHANNEL PACKET \n %p",struct_read_packet), UVM_NONE);
`ifdef DMA350_CMDLINK_HOOK
        // --------------------------------------------------------------------
        // DESCRIPTOR / AUTOBOOT fetch hook (chi khi +define+DMA350_CMDLINK_HOOK).
        // Neu dia chi AR da duoc nap trong dma350_cmdlink_mem_pkg -> tra ve BYTE
        // da nap thay cho du lieu ngau nhien, de DUT nap dung header command-link
        // / boot. Guard = cmdlink_mem_has(araddr): rong voi moi test khong dung
        // command-link nen KHONG anh huong (1d/trigger...).
        // --------------------------------------------------------------------
        if (dma350_cmdlink_mem_pkg::cmdlink_mem_has(local_slave_addr_chk_tx.araddr)) begin
          int unsigned nb_desc  = local_slave_addr_chk_tx.arlen + 1;
          int unsigned bpb_desc = (1 << local_slave_addr_chk_tx.arsize);
          for (int di = 0; di < nb_desc; di++) begin
            struct_read_packet.rdata[di] = '0;
            for (int db = 0; db < bpb_desc; db++)
              struct_read_packet.rdata[di][8*db +: 8] =
                dma350_cmdlink_mem_pkg::cmdlink_mem_get(local_slave_addr_chk_tx.araddr + di*bpb_desc + db);
            struct_read_packet.rresp[di] = READ_OKAY;
          end
          `uvm_info("DMA350_CMDLINK",$sformatf(
            "descriptor fetch @0x%0h len=%0d size=%0d -> tra du lieu da nap",
            local_slave_addr_chk_tx.araddr, local_slave_addr_chk_tx.arlen,
            local_slave_addr_chk_tx.arsize), UVM_MEDIUM)
        end
`endif
        //read data task
        axi5_slave_drv_bfm_h.axi5_read_data_phase(struct_read_packet,struct_cfg,axi5_slave_agent_cfg_h.slave_response_mode);
        `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("AFTER :: READ CHANNEL PACKET \n %p",struct_read_packet), UVM_NONE);
      end
      else if (axi5_slave_agent_cfg_h.read_data_mode == SLAVE_MEM_MODE || axi5_slave_agent_cfg_h.read_data_mode == SLAVE_ERR_RESP_MODE && write_read_mode_h != ONLY_READ_DATA) begin
        semaphore_read_key.get(1);
        while((!memory_write_count.exists(local_slave_addr_chk_tx.araddr)) || (memory_write_count[local_slave_addr_chk_tx.araddr] == 0)) begin
           `uvm_info(get_type_name(), $sformatf("waiting write_complete_event"), UVM_NONE);
        
          if (memory_write_count.size() == 0) begin
              `uvm_info(get_type_name(), "Mang memory_write_count dang TRONG (Empty)!", UVM_NONE);
          end else begin
              // Lặp qua tất cả các phần tử (key) đang có trong mảng
              foreach (memory_write_count[addr]) begin
                  `uvm_info(get_type_name(), $sformatf(" -> [Da Luu] Dia chi: 0x%0h | Count: %0d", addr, memory_write_count[addr]), UVM_NONE);
              end
          end 
          @(write_complete_event);
        end
       // wait(memory_write_count.exists(local_slave_addr_chk_tx.araddr) && memory_write_count[local_slave_addr_chk_tx.araddr] > 0);

        `uvm_info(get_type_name(), $sformatf("read Address exists in memory model "), UVM_NONE);
        //Converting transactions into struct data type
        axi5_slave_seq_item_converter::from_read_class(local_slave_rdata_tx,struct_read_packet);
        `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_read_packet = \n %0p",struct_read_packet), UVM_NONE); 
  
        //Converting configurations into struct config type
        axi5_slave_cfg_converter::from_class(axi5_slave_agent_cfg_h,struct_cfg);
        `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_cfg =  \n %0p",struct_cfg),UVM_HIGH);

        if((axi5_slave_agent_cfg_h.slave_response_mode == ONLY_READ_RESP_OUT_OF_ORDER) || (axi5_slave_agent_cfg_h.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER) ) begin
          out_of_order_for_reads(struct_read_packet);
          `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_read_packet = \n %0p",struct_read_packet), UVM_NONE); 
        end
        
        total_bytes = (local_slave_addr_chk_tx.arlen+1)*(2**(local_slave_addr_chk_tx.arsize));
        if(local_slave_addr_chk_tx.araddr inside {[axi5_slave_agent_cfg_h.min_address : axi5_slave_agent_cfg_h.max_address]}) begin : ADDR_INSIDE_SLAVE_MEM_RANGE
          if(local_slave_addr_chk_tx.arburst == READ_FIXED) begin
            task_memory_read(local_slave_addr_chk_tx,struct_read_packet);
            if(crossed_read_addr) begin 
              for(int depth=0;depth<(local_slave_addr_chk_tx.arlen+1);depth++) begin
                struct_read_packet.rresp[depth] = READ_SLVERR; 
              end
            end
            else begin 
              struct_read_packet.rresp = READ_OKAY;
            end
            //read data task
            axi5_slave_drv_bfm_h.axi5_read_data_phase(struct_read_packet,struct_cfg,axi5_slave_agent_cfg_h.slave_response_mode);
            `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("AFTER :: READ_CHANNEL_PACKET \n%p",struct_read_packet), UVM_NONE);
          end else if(local_slave_addr_chk_tx.arburst == READ_WRAP || local_slave_addr_chk_tx.arburst == READ_INCR) begin
            if(axi5_slave_mem_h.is_slave_addr_exists(local_slave_addr_chk_tx.araddr)) begin
              `uvm_info(get_type_name(),$sformatf("local_slave_addr_chk_tx",local_slave_addr_chk_tx.sprint()),UVM_LOW); 
              task_memory_read(local_slave_addr_chk_tx,struct_read_packet);
              for(int j=0,int loc=0;j<total_bytes;j++) begin
                if((local_slave_addr_chk_tx.araddr+j)==crossed_read_addr) begin
                  loc = j/STROBE_WIDTH;
                  for(int depth=0;depth<(local_slave_addr_chk_tx.arlen+1);depth++) begin
                    if(depth > loc) struct_read_packet.rresp[depth] = READ_SLVERR;
                    else struct_read_packet.rresp[depth] = READ_OKAY;
                  end
                  break;
                end            
              end
                //read data task
                axi5_slave_drv_bfm_h.axi5_read_data_phase(struct_read_packet,struct_cfg,axi5_slave_agent_cfg_h.slave_response_mode);
                `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("AFTER :: READ_CHANNEL_PACKET \n%p",struct_read_packet), UVM_NONE);
            end else begin
              axi5_slave_agent_cfg_h.user_rdata = (local_slave_addr_chk_tx.arsize ==
              READ_1_BYTE)?32'ha:((local_slave_addr_chk_tx.arsize ==
              READ_2_BYTES)?32'haa:((local_slave_addr_chk_tx.arsize ==
              READ_4_BYTES)?32'hdead_beaf:{DATA_WIDTH{16'habcd}}));
              for(int i=0;i<local_slave_addr_chk_tx.arlen+1;i++) begin
                struct_read_packet.rdata[i] =  axi5_slave_agent_cfg_h.user_rdata;
              end
              //read data task
              axi5_slave_drv_bfm_h.axi5_read_data_phase(struct_read_packet,struct_cfg,axi5_slave_agent_cfg_h.slave_response_mode);
              `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("AFTER :: READ_CHANNEL_PACKET \n%p",struct_read_packet), UVM_NONE);
              `uvm_error("AXI5_SLAVE_DRIVER_PROXY",$sformatf("ADDRESS trying to read DOESN'T EXIST in the slave memory... READING DEFAULT VALUES...."));
            end
          end
        end else begin : ADDR_NOT_INSIDE_SLAVE_MEM_RANGE
          for(int depth=0;depth<(((axi5_slave_agent_cfg_h.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER) || (axi5_slave_agent_cfg_h.slave_response_mode == ONLY_READ_RESP_OUT_OF_ORDER))  ? (struct_read_packet.arlen+1) : (local_slave_addr_chk_tx.arlen+1));depth++) begin
            struct_read_packet.rresp[depth] = READ_SLVERR; 
          end
          $display("rspp:%0p,id:%0h,len:%0h",struct_read_packet.rdata,struct_read_packet.arid,struct_read_packet.arlen);
          //read data task
          axi5_slave_drv_bfm_h.axi5_read_data_phase(struct_read_packet,struct_cfg,axi5_slave_agent_cfg_h.slave_response_mode);
          `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("AFTER :: READ CHANNEL PACKET \n %p",struct_read_packet), UVM_HIGH);
        end
      end
      //Calling converter class for reads to convert struct to req
      axi5_slave_seq_item_converter::to_read_class(struct_read_packet,local_slave_rdata_tx);
      `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("AFTER :: READ CHANNEL PACKET \n %s",local_slave_rdata_tx.sprint()), UVM_HIGH);

      //Getting teh sampled read address from read address fifo
      axi5_slave_read_addr_fifo_h.get(local_slave_raddr_tx);
      
      //Calling the Combined coverter class to combine read address and read data packet
      axi5_slave_seq_item_converter::tx_read_packet(local_slave_raddr_tx,local_slave_rdata_tx,packet);
      `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("AFTER :: COMBINED READ CHANNEL PACKET \n%s",packet.sprint()), UVM_NONE);
      
      //Putting back the key
      semaphore_read_key.put(1);
    end
  join_any
 
  //Check the status of read address thread
    rd_addr.await();
    `uvm_info("SLAVE_STATUS_CHECK",$sformatf("AFTER_FORK_JOIN_ANY:: SLAVE_READ_CHANNEL_STATUS = \n %s",rd_addr.status()),UVM_MEDIUM)
    `uvm_info("SLAVE_STATUS_CHECK",$sformatf("AFTER_FORK_JOIN_ANY:: SLAVE_RDATA_CHANNEL_STATUS = \n %s",rd_data.status()),UVM_MEDIUM)

    axi_read_seq_item_port.item_done();
  end

endtask : axi5_read_task

//--------------------------------------------------------------------------------------------
// Task: task_memory_write
// This task is used to write the data into the slave memory
// Parameters:
//  struct_packet   - axi5_write_transfer_char_s
//--------------------------------------------------------------------------------------------

task axi5_slave_driver_proxy::task_memory_write(inout axi5_slave_tx struct_write_packet);
  int lower_addr,end_addr,k_t,k_scale;
  if(struct_write_packet.awburst == WRITE_FIXED) begin
    for(int j=0;j<(struct_write_packet.awlen+1);j++)begin
      `uvm_info("DEBUG_MEMORY_WRITE",$sformatf("memory_task_awlen=%d",struct_write_packet.awlen),UVM_HIGH)
        for(int strb=0;strb<STROBE_WIDTH;strb++) begin
        `uvm_info("DEBUG_MEMORY_WRITE", $sformatf("task_memory_write inside for loop wstrb = %0h",struct_write_packet.wstrb[strb]), UVM_HIGH);
        if(struct_write_packet.wstrb[j][strb] == 1) begin
      	`uvm_info("ADDRESS_MEMORY_WRITE",$sformatf("memory_task_awaddr=%d data=%h",struct_write_packet.awaddr, struct_write_packet.wdata[j][8*strb+7 -: 8]),UVM_NONE)
          axi5_slave_mem_h.fifo_write(struct_write_packet.wdata[j][8*strb+7 -: 8]);
        end
      end
    end
  end
  if(struct_write_packet.awburst == WRITE_INCR) begin
    for(int j=0,int k=0;j<(struct_write_packet.awlen+1);j++)begin
      `uvm_info("DEBUG_MEMORY_WRITE",$sformatf("memory_task_awlen=%d",struct_write_packet.awlen),UVM_HIGH)
        for(int strb=0;strb<STROBE_WIDTH;strb++) begin
        `uvm_info("DEBUG_MEMORY_WRITE", $sformatf("task_memory_write inside for loop wstrb = %0h,k=%0d",struct_write_packet.wstrb[strb],k), UVM_HIGH);
        if(struct_write_packet.wstrb[j][strb] == 1) begin
      	`uvm_info("ADDRESS_MEMORY_WRITE",$sformatf("memory_task_awaddr=%d data=%h",struct_write_packet.awaddr+k, struct_write_packet.wdata[j][8*strb+7 -: 8]),UVM_NONE)
          axi5_slave_mem_h.mem_write(struct_write_packet.awaddr+k,struct_write_packet.wdata[j][8*strb+7 -: 8]);
          k++;
        end
      end
    end
  end
  if(struct_write_packet.awburst == WRITE_WRAP) begin
    lower_addr = struct_write_packet.awaddr - int'(struct_write_packet.awaddr%((struct_write_packet.awlen+1)*(2**struct_write_packet.awsize)));
    end_addr = lower_addr + ((struct_write_packet.awlen+1)*(2**struct_write_packet.awsize));
    k_t = struct_write_packet.awaddr;
		k_scale = - int'(struct_write_packet.awaddr%((struct_write_packet.awlen+1)*(2**struct_write_packet.awsize)));
    for(int j=0,int k=0;j<(struct_write_packet.awlen+1);j++)begin
      `uvm_info("DEBUG_MEMORY_WRITE",$sformatf("memory_task_awlen=%d",struct_write_packet.awlen),UVM_HIGH)
        for(int strb=0;strb<STROBE_WIDTH;strb++) begin
        `uvm_info("DEBUG_MEMORY_WRITE", $sformatf("task_memory_write inside for loop wstrb = %0h,k=%0d",struct_write_packet.wstrb[strb],k), UVM_HIGH);
          if(struct_write_packet.wstrb[j][strb] == 1) begin
            if(k_t < end_addr)  begin
      			`uvm_info("ADDRESS_MEMORY_WRITE",$sformatf("memory_task_awaddr=%d data=%h",struct_write_packet.awaddr+k, struct_write_packet.wdata[j][8*strb+7 -: 8]),UVM_NONE)
            axi5_slave_mem_h.mem_write(struct_write_packet.awaddr+k,struct_write_packet.wdata[j][8*strb+7 -: 8]);
            k++;
            k_t++;
            if(k_t == end_addr) k = 0; //!!!!
          end
          else begin
      			`uvm_info("ADDRESS_MEMORY_WRITE",$sformatf("memory_task_awaddr=%d data=%h",struct_write_packet.awaddr+k, struct_write_packet.wdata[j][8*strb+7 -: 8]),UVM_NONE)
            axi5_slave_mem_h.mem_write(lower_addr+k,struct_write_packet.wdata[j][8*strb+7 -: 8]);
            k++;
          end
        end
      end
    end
  end

endtask : task_memory_write

task axi5_slave_driver_proxy::task_memory_read(input axi5_slave_tx read_pkt,output axi5_read_transfer_char_s struct_read_packet);
  int lower_addr,end_addr,k_t,k_rstat;
  if(read_pkt.arburst == READ_FIXED) begin
    for(int j=0,int k=0;j<(read_pkt.arlen+1);j++)begin
      `uvm_info("DEBUG_MEMORY_WRITE",$sformatf("memory_task_arlen=%d",read_pkt.arlen),UVM_HIGH)
      for(int strb=0;strb<(2**(read_pkt.arsize));strb++) begin
      	`uvm_info("ADDRESS_MEMORY_READ",$sformatf("memory_task_araddr=%d data=%h",read_pkt.araddr, struct_read_packet.rdata[j][8*strb+7 -: 8]),UVM_NONE)
        axi5_slave_mem_h.fifo_read(struct_read_packet.rdata[j][8*strb+7 -: 8]);
        k++;
      end
    end
    if((read_pkt.araddr+((2**(read_pkt.arsize))))> axi5_slave_agent_cfg_h.max_address) begin 
      crossed_read_addr = 1;
    end
    else crossed_read_addr = 0;
  end
  if(read_pkt.arburst == READ_INCR) begin
    for(int j=0,int k=0;j<(read_pkt.arlen+1);j++)begin
      `uvm_info("DEBUG_MEMORY_WRITE",$sformatf("memory_task_arlen=%d",read_pkt.arlen),UVM_HIGH)
        for(int strb=0;strb<(2**(read_pkt.arsize));strb++) begin
          axi5_slave_mem_h.mem_read(read_pkt.araddr+k,struct_read_packet.rdata[j][8*strb+7 -: 8]);
      		`uvm_info("ADDRESS_MEMORY_READ",$sformatf("memory_task_araddr=%d data=%h",read_pkt.araddr+k, struct_read_packet.rdata[j][8*strb+7 -: 8]),UVM_NONE)
          if(read_pkt.araddr+k > axi5_slave_agent_cfg_h.max_address) begin 
            crossed_read_addr = read_pkt.araddr+k;
          end
          k++;
        end
      end
    end
  if(read_pkt.arburst == READ_WRAP) begin
    lower_addr = read_pkt.araddr - int'(read_pkt.araddr%((read_pkt.arlen+1)*(2**read_pkt.arsize)));
    end_addr = lower_addr + ((read_pkt.arlen+1)*(2**read_pkt.arsize));
    k_t = read_pkt.araddr;
		k_rstat = - int'(read_pkt.araddr%((read_pkt.arlen+1)*(2**read_pkt.arsize)));
    for(int j=0,int k=0;j<(read_pkt.arlen+1);j++)begin
      `uvm_info("DEBUG_MEMORY_WRITE",$sformatf("memory_task_arlen=%d",read_pkt.arlen),UVM_HIGH)
        for(int strb=0;strb<(2**(read_pkt.arsize));strb++) begin
          if(k_t < end_addr)  begin
             axi5_slave_mem_h.mem_read(read_pkt.araddr+k,struct_read_packet.rdata[j][8*strb+7 -: 8]);
      			`uvm_info("ADDRESS_MEMORY_READ",$sformatf("memory_task_araddr=%d data=%h",read_pkt.araddr+k, struct_read_packet.rdata[j][8*strb+7 -: 8]),UVM_NONE)
             if(read_pkt.araddr+k > axi5_slave_agent_cfg_h.max_address) crossed_read_addr = read_pkt.araddr+k;
             k++;
             k_t++;
             if(k_t == end_addr) k = 0;
          end
          else begin
            axi5_slave_mem_h.mem_read(lower_addr+k,struct_read_packet.rdata[j][8*strb+7 -: 8]);
      			`uvm_info("ADDRESS_MEMORY_READ",$sformatf("memory_task_araddr=%d data=%h",lower_addr+k, struct_read_packet.rdata[j][8*strb+7 -: 8]),UVM_NONE)
             if(crossed_read_addr == -1) begin
               if(lower_addr+k > axi5_slave_agent_cfg_h.max_address) crossed_read_addr = lower_addr+k;
             end
            k++;
          end
        end
      end
    end
endtask : task_memory_read


task axi5_slave_driver_proxy::out_of_order_for_reads(output axi5_read_transfer_char_s oor_read_data_struct_read_packet);
 $display("Inside_read_OOR");
 wait(axi5_slave_read_addr_fifo_h.size > axi5_slave_agent_cfg_h.get_minimum_transactions); 
 `uvm_info("slave_driver_proxy",$sformatf("fifo_size = %0d",axi5_slave_read_addr_fifo_h.used()),UVM_NONE)
 if(drive_rd_id_cont == 1) begin
   oor_read_data_struct_read_packet = rd_response_id_cont_queue.pop_front(); 
   if(rd_response_id_cont_queue.size()==0) drive_rd_id_cont = 1'b0;
 end
 else begin
   rd_response_id_queue.shuffle();
   oor_read_data_struct_read_packet = rd_response_id_queue.pop_front(); 
 end
endtask : out_of_order_for_reads

`endif
