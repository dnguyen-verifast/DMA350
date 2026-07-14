`ifndef AXI5_SLAVE_MONITOR_PROXY_INCLUDED_
`define AXI5_SLAVE_MONITOR_PROXY_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_slave_monitor_proxy
// This is the HVL axi5_slave monitor proxy
// It gets the sampled data from the HDL axi5_slave monitor and 
// converts them into transaction items
//--------------------------------------------------------------------------------------------
class axi5_slave_monitor_proxy extends uvm_monitor;
  `uvm_component_utils(axi5_slave_monitor_proxy)

  // Variable: axi5_slave_agent_cfg_h;
  // Handle for axi5 slave agent configuration
  axi5_slave_agent_config axi5_slave_agent_cfg_h;

  // Declaring Virtual Monitor BFM Handle
  virtual axi5_slave_monitor_bfm axi5_slave_mon_bfm_h;

  axi5_slave_tx req_rd;

  // Variable: axi5_slave_analysis_port
  // Declaring analysis port for the monitor port
  uvm_analysis_port#(axi5_slave_tx) axi5_slave_write_address_analysis_port;
  uvm_analysis_port#(axi5_slave_tx) axi5_slave_write_data_analysis_port;
  uvm_analysis_port#(axi5_slave_tx) axi5_slave_write_response_analysis_port;
  uvm_analysis_port#(axi5_slave_tx) axi5_slave_read_address_analysis_port;
  uvm_analysis_port#(axi5_slave_tx) axi5_slave_read_data_analysis_port;

  //Variable: axi5_slave_write_address_fifo_h
  //Declaring handle for uvm_tlm_analysis_fifo for write task
  uvm_tlm_analysis_fifo #(axi5_slave_tx) axi5_slave_write_address_fifo_h;
  
  //Variable: axi5_slave_write_data_fifo_h
  //Declaring handle for uvm_tlm_analysis_fifo for write task
  uvm_tlm_analysis_fifo #(axi5_slave_tx) axi5_slave_write_data_fifo_h;
  
  //Variable: axi5_slave_read_fifo_h
  //Declaring handle for uvm_tlm_analysis_fifo for read task
  uvm_tlm_analysis_fifo #(axi5_slave_tx) axi5_slave_read_fifo_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_slave_monitor_proxy", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task axi5_slave_write_address();
  extern virtual task axi5_slave_write_data();
  extern virtual task axi5_slave_write_response();
  extern virtual task axi5_slave_read_address();
  extern virtual task axi5_slave_read_data();
  extern virtual  function axi5_slave_tx  strobe_generation(axi5_slave_tx req);

endclass : axi5_slave_monitor_proxy

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi5_slave_monitor_proxy
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi5_slave_monitor_proxy::new(string name = "axi5_slave_monitor_proxy",
                                 uvm_component parent = null);
  super.new(name, parent);
  axi5_slave_read_address_analysis_port = new("axi5_slave_read_address_analysis_port",this);
  axi5_slave_read_data_analysis_port = new("axi5_slave_read_data_analysis_port",this);
  axi5_slave_write_address_analysis_port = new("axi5_slave_write_address_analysis_port",this);
  axi5_slave_write_data_analysis_port = new("axi5_slave_write_data_analysis_port",this);
  axi5_slave_write_response_analysis_port = new("axi5_slave_write_response_analysis_port",this);
  axi5_slave_write_address_fifo_h= new("axi5_slave_write_address_fifo_h",this);
  axi5_slave_write_data_fifo_h= new("axi5_slave_write_data_fifo_h",this);
  axi5_slave_read_fifo_h = new("axi5_slave_read_fifo_h",this);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_slave_monitor_proxy::build_phase(uvm_phase phase);
  super.build_phase(phase);
   if(!uvm_config_db#(virtual axi5_slave_monitor_bfm)::get(this,"","axi5_slave_monitor_bfm",axi5_slave_mon_bfm_h)) begin
     `uvm_fatal("FATAL_SMP_MON_BFM",$sformatf("Couldn't get S_MON_BFM in axi5_slave_monitor_proxy"));  
  end 
endfunction : build_phase

//-------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
//Description: connects monitor_proxy and monitor_bfm
//
// Parameters:
//  phase - stores the current phase
//------------------------------------------------------------------------------------------
function void axi5_slave_monitor_proxy::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  axi5_slave_mon_bfm_h.axi5_slave_mon_proxy_h = this;
endfunction : end_of_elaboration_phase


//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi5_slave_monitor_proxy::run_phase(uvm_phase phase);

  axi5_slave_mon_bfm_h.wait_for_aresetn();

  fork 
    axi5_slave_write_address();
    axi5_slave_write_data();
    axi5_slave_write_response();
    axi5_slave_read_address();
    axi5_slave_read_data();
  join

endtask : run_phase 

//--------------------------------------------------------------------------------------------
// Task : axi5_slave_write_address
// Description: converting,sampling and again converting 
//--------------------------------------------------------------------------------------------
task axi5_slave_monitor_proxy::axi5_slave_write_address();
  forever begin
    axi5_write_transfer_char_s struct_write_packet;
    axi5_transfer_cfg_s        struct_cfg;
    axi5_slave_tx              req_wr_clone_packet;
    axi5_slave_tx req_wr;
    logic [31:0] end_wrap_addr;
    logic [31:0] min_addr;

    axi5_slave_cfg_converter::from_class(axi5_slave_agent_cfg_h, struct_cfg);
    axi5_slave_mon_bfm_h.axi5_slave_write_address_sampling(struct_write_packet,struct_cfg);
    axi5_slave_seq_item_converter::to_write_class(struct_write_packet,req_wr);

    // checking for address exceeding 4kb boundary
    if(req_wr.awburst == WRITE_FIXED) begin
        end_wrap_addr =  req_wr.awaddr;
    end
    if(req_wr.awburst == WRITE_INCR) begin
      end_wrap_addr =  req_wr.awaddr + ((req_wr.awlen+1)*(2**req_wr.awsize));
    end
    if(req_wr.awburst == WRITE_WRAP) begin
      if(req_wr.awaddr%(2**req_wr.awsize) != 0) begin
        `uvm_error("SLAVE_MONITOR",$sformatf("Address is not aligned to Wrap burst. Marking as error"));
      end else begin
        `uvm_info("SLAVE_MONITOR",$sformatf("Address is aligned to Wrap burst."),UVM_LOW);
      end
       end_wrap_addr = req_wr.awaddr - int'(req_wr.awaddr%((req_wr.awlen+1)*(2**req_wr.awsize)));
       min_addr = req_wr.awaddr - int'(req_wr.awaddr%((req_wr.awlen+1)*(2**req_wr.awsize)));
       end_wrap_addr = end_wrap_addr + ((req_wr.awlen+1)*(2**req_wr.awsize));
    end
    if(min_addr[31:12] != req_wr.awaddr[31:12] || end_wrap_addr[31:12] != req_wr.awaddr[31:12]) begin
      `uvm_error("SLAVE_MONITOR",$sformatf("Address write exceed 4kb boundary. Marking as error")); end
    else begin 
      `uvm_info("SLAVE_MONITOR",$sformatf("Address write is within 4kb boundary."),UVM_LOW);
    end

    // Checking for burst length 
    if(req_wr.awburst == WRITE_WRAP && (req_wr.awlen > 15 || (req_wr.awlen + 1)%2 != 0)) begin
      `uvm_error("SLAVE_MONITOR",$sformatf("Burst length is greater than 16. Marking as error"));
    end else begin
      `uvm_info("SLAVE_MONITOR",$sformatf("Burst length is less than or equal to 16."),UVM_LOW);
    end
    if(req_wr.awburst == WRITE_FIXED && req_wr.awlen > 15) begin
      `uvm_error("SLAVE_MONITOR",$sformatf("Burst type is FIXED but burst length is not 1. Marking as error"));
    end else begin
      `uvm_info("SLAVE_MONITOR",$sformatf("Burst type and burst length are consistent."),UVM_LOW);
    end
    if(req_wr.awburst == WRITE_INCR && req_wr.awlen > 255) begin
      `uvm_error("SLAVE_MONITOR",$sformatf("Burst length is greater than 256. Marking as error"));
    end else begin
      `uvm_info("SLAVE_MONITOR",$sformatf("Burst length is less than or equal to 256."),UVM_LOW);
    end
    // Checking transfer size 
    if(8*(2**req_wr.awsize) > DATA_WIDTH) begin
      `uvm_error("SLAVE_MONITOR",$sformatf("Transfer size is greater than DATA_WIDTH. Marking as error"));
    end else begin
      `uvm_info("SLAVE_MONITOR",$sformatf("Transfer size is less than or equal to DATA_WIDTH."),UVM_LOW);
    end

    
    axi5_slave_write_address_fifo_h.put(req_wr);

    $cast(req_wr_clone_packet,req_wr.clone());    
    `uvm_info(get_type_name(),$sformatf("Packet received from axi5_slave_write_address_sampling is %s",req_wr_clone_packet.sprint()),UVM_HIGH)
    axi5_slave_write_address_analysis_port.write(req_wr_clone_packet);

  end
endtask
//--------------------------------------------------------------------------------------------
// Task: axi5_slave_write_data
//  Gets the struct packet samples the data, convert it to req and drives to analysis port
//--------------------------------------------------------------------------------------------

task axi5_slave_monitor_proxy::axi5_slave_write_data();
  forever begin

    axi5_write_transfer_char_s struct_write_packet;

    axi5_transfer_cfg_s        struct_cfg;
    axi5_slave_tx             req_wr_clone_packet;
    axi5_slave_tx             local_write_addr_packet;
    axi5_slave_tx req_wr;
    int                       beat_count = 0;
    axi5_slave_cfg_converter::from_class(axi5_slave_agent_cfg_h, struct_cfg);
    axi5_slave_mon_bfm_h.axi5_slave_write_data_sampling(struct_write_packet,struct_cfg,beat_count);
    axi5_slave_seq_item_converter::to_write_class(struct_write_packet,req_wr);
    `uvm_info(get_type_name(),$sformatf("DATA_Packet received bfm is \n %s",req_wr.sprint()),UVM_LOW)
    
    //Getting the write address packet
    axi5_slave_write_address_fifo_h.get(local_write_addr_packet);
    `uvm_info(get_type_name(),$sformatf("ADDR_Packet received from fifo is \n %s",local_write_addr_packet.sprint()),UVM_LOW)   
    local_write_addr_packet = strobe_generation(local_write_addr_packet);
    `uvm_info(get_type_name(),$sformatf("Strobe for ADDR_Packet received from fifo is \n %s",local_write_addr_packet.sprint()),UVM_LOW) 
    //Combining write address and write data packets
    
    //Checking total beat count with burst length to avoid any mismatch11
    if(beat_count != local_write_addr_packet.awlen) begin
      `uvm_error("SLAVE_MONITOR",$sformatf("Beat count is not equal to burst length. Marking as error beat_count = %0d",beat_count));
    end else begin
      `uvm_info("SLAVE_MONITOR",$sformatf("Beat count is equal to burst length."),UVM_HIGH);
    end
    // checking for trobe mismatch with address and size
    for (int i = 0; i < local_write_addr_packet.awlen+1; i++) begin
      if(local_write_addr_packet.wstrb[i] != req_wr.wstrb[i]) begin
        `uvm_error("SLAVE_MONITOR",$sformatf("Wstrb[%0d] mismatch with address and size. Marking as error local_write_addr_packet.wstrb = %0h != req_wr.wstrb = %0h",i,local_write_addr_packet.wstrb[i],req_wr.wstrb[i]));
      end else begin
        `uvm_info("SLAVE_MONITOR",$sformatf("Wstrb is consistent with address and size."),UVM_HIGH);
      end
    end

    axi5_slave_write_data_fifo_h.put(req_wr);
    //clone and publish the clone to the analysis port
    axi5_slave_seq_item_converter::to_write_addr_data_class(local_write_addr_packet,struct_write_packet,req_wr); 
    $cast(req_wr_clone_packet,req_wr.clone());
    `uvm_info(get_type_name(),$sformatf("Packet received from axi5_slave_write_data is \n %s",req_wr_clone_packet.sprint()),UVM_HIGH)
    axi5_slave_write_data_analysis_port.write(req_wr);
  end

endtask
//--------------------------------------------------------------------------------------------
// Task: axi5_slave_write_response
//  Gets the struct packet samples the data, convert it to req and drives to analysis port
//--------------------------------------------------------------------------------------------

task axi5_slave_monitor_proxy::axi5_slave_write_response();

  forever begin
    axi5_write_transfer_char_s struct_write_packet;
    axi5_transfer_cfg_s        struct_cfg;
    axi5_slave_tx req_wr;
    axi5_slave_tx             axi5_slave_tx_clone_packet;
    axi5_slave_tx             local_write_addr_data_packet;

    axi5_slave_cfg_converter::from_class(axi5_slave_agent_cfg_h, struct_cfg);
    axi5_slave_mon_bfm_h.axi5_write_response_sampling(struct_write_packet,struct_cfg);
    axi5_slave_seq_item_converter::to_write_class(struct_write_packet,req_wr);
    
    //Getting the write address packet
    axi5_slave_write_data_fifo_h.get(local_write_addr_data_packet);
    
    //Combining write address and write data packets
    axi5_slave_seq_item_converter::to_write_addr_data_resp_class(local_write_addr_data_packet,struct_write_packet,req_wr);

    //clone and publish the clone to the analysis port 
    $cast(axi5_slave_tx_clone_packet,req_wr.clone());
    `uvm_info(get_type_name(),$sformatf("Packet received from axi5_slave_write_response is \n %s",axi5_slave_tx_clone_packet.sprint()),UVM_HIGH);
    
    axi5_slave_write_response_analysis_port.write(axi5_slave_tx_clone_packet);
  end
endtask

//--------------------------------------------------------------------------------------------
// Task: axi5_slave_read_address
//  Gets the struct packet samples the data, convert it to req and drives to analysis port
//--------------------------------------------------------------------------------------------

task axi5_slave_monitor_proxy::axi5_slave_read_address();
  forever begin
    axi5_read_transfer_char_s struct_read_packet;
    axi5_transfer_cfg_s        struct_cfg;
    axi5_slave_tx             req_rd_clone_packet;
    logic [31:0] end_wrap_addr;
    logic [31:0] min_addr;
    axi5_slave_cfg_converter::from_class(axi5_slave_agent_cfg_h, struct_cfg);
    axi5_slave_mon_bfm_h.axi5_read_address_sampling(struct_read_packet,struct_cfg);
    axi5_slave_seq_item_converter::to_read_class(struct_read_packet,req_rd);

    // checking for address exceeding 4kb boundary
    if(req_rd.arburst == READ_FIXED) begin
        end_wrap_addr =  req_rd.araddr;
      end
      if(req_rd.arburst == READ_INCR) begin
        end_wrap_addr =  req_rd.araddr + ((req_rd.arlen+1)*(2**req_rd.awsize));
      end
      if(req_rd.arburst == READ_WRAP) begin
        if(req_rd.araddr%(2**req_rd.arsize) != 0) begin
          `uvm_error("SLAVE_MONITOR",$sformatf("Address is not aligned to Wrap burst. Marking as error"));
        end else begin
          `uvm_info("SLAVE_MONITOR",$sformatf("Address is aligned to Wrap burst."),UVM_LOW);
        end
         end_wrap_addr = req_rd.araddr - int'(req_rd.araddr%((req_rd.arlen+1)*(2**req_rd.arsize)));
         min_addr = req_rd.araddr - int'(req_rd.araddr%((req_rd.arlen+1)*(2**req_rd.arsize)));
         end_wrap_addr = end_wrap_addr + ((req_rd.arlen+1)*(2**req_rd.arsize));
      end
    if(min_addr[31:12] != req_rd.araddr[31:12] || end_wrap_addr[31:12] != req_rd.araddr[31:12]) begin
      `uvm_error("SLAVE_MONITOR",$sformatf("Address read exceed 4kb boundary. Marking as error"));
    end else begin `uvm_info("SLAVE_MONITOR",$sformatf("Address read is within 4kb boundary."),UVM_LOW); end

    // Checking for burst length 
    if(req_rd.arburst == READ_WRAP && (req_rd.arlen > 15 || (req_rd.arlen + 1)%2 != 0)) begin
      `uvm_error("SLAVE_MONITOR",$sformatf("Burst length is greater than 16. Marking as error"));
    end else begin
      `uvm_info("SLAVE_MONITOR",$sformatf("Burst length is less than or equal to 16."),UVM_LOW);
    end
    if(req_rd.arburst == READ_FIXED && req_rd.arlen > 15) begin
      `uvm_error("SLAVE_MONITOR",$sformatf("Burst type is FIXED but burst length is not 1. Marking as error"));
    end else begin
      `uvm_info("SLAVE_MONITOR",$sformatf("Burst type and burst length are consistent."),UVM_LOW);
    end
    if(req_rd.arburst == READ_INCR && req_rd.arlen > 255) begin
      `uvm_error("SLAVE_MONITOR",$sformatf("Burst length is greater than 256. Marking as error"));
    end else begin
      `uvm_info("SLAVE_MONITOR",$sformatf("Burst length is less than or equal to 256."),UVM_LOW);
    end
    // Checking transfer size 
    if(8*(2**req_rd.arsize) > DATA_WIDTH) begin
      `uvm_error("SLAVE_MONITOR",$sformatf("Transfer size is greater than DATA_WIDTH. Marking as error"));
    end else begin
      `uvm_info("SLAVE_MONITOR",$sformatf("Transfer size is less than or equal to DATA_WIDTH."),UVM_LOW);
    end

    axi5_slave_read_fifo_h.put(req_rd);

    $cast(req_rd_clone_packet,req_rd.clone());
    `uvm_info(get_type_name(),$sformatf("Packet received from axi5_slave_read_address is \n %s",req_rd_clone_packet.sprint()),UVM_HIGH)

    axi5_slave_read_address_analysis_port.write(req_rd_clone_packet); 
  end

endtask

//--------------------------------------------------------------------------------------------
// Task: axi5_slave_read_data
//  Gets the struct packet samples the data, convert it to req and drives to analysis port
//--------------------------------------------------------------------------------------------

task axi5_slave_monitor_proxy::axi5_slave_read_data();
  forever begin
    axi5_read_transfer_char_s struct_read_packet;
    axi5_transfer_cfg_s       struct_cfg;
    axi5_slave_tx             req_rd_clone_packet; 
    axi5_slave_tx             local_read_addr_packet;
    int                      beat_read_count = 0; 

    axi5_slave_cfg_converter::from_class(axi5_slave_agent_cfg_h, struct_cfg);
    axi5_slave_mon_bfm_h.axi5_read_data_sampling(struct_read_packet,struct_cfg,beat_read_count);
    axi5_slave_seq_item_converter::to_read_class(struct_read_packet,req_rd);
    axi5_slave_read_fifo_h.get(local_read_addr_packet);
     `uvm_info(get_type_name(),$sformatf("READ_ADDR_Packet received from fifo is \n %s",local_read_addr_packet.sprint()),UVM_HIGH)
     
    if(beat_read_count != local_read_addr_packet.arlen) begin
      `uvm_error("SLAVE_MONITOR",$sformatf("Beat count is not equal to burst length. Marking as error beat_read_count = %0d  arlen = %0d",beat_read_count, req_rd.arlen));
    end else begin
      `uvm_info("SLAVE_MONITOR",$sformatf("Beat count is equal to burst length."),UVM_LOW);
    end
      
    axi5_slave_seq_item_converter::to_read_addr_data_class(local_read_addr_packet,struct_read_packet,req_rd);
    //clone and publish the clone to the analysis port 
    $cast(req_rd_clone_packet,req_rd.clone());
    `uvm_info(get_type_name(),$sformatf("Packet received from axi5_slave_read_data is \n %s",req_rd_clone_packet.sprint()),UVM_HIGH)

    axi5_slave_read_data_analysis_port.write(req_rd_clone_packet);
  end
endtask

function axi5_slave_tx axi5_slave_monitor_proxy::strobe_generation(axi5_slave_tx req);
  bit[3:0] wstrb_local;
  bit[3:0] wstrb_size_0_local;
  bit[3:0] awsize_0;
  bit[3:0] awsize_1;

  bit[3:0] unallignd_wstrb0;
  bit[3:0] unallignd_wstrb1;
  bit[3:0] unallignd_wstrb2;
  bit[1:0] unallignd_wstrb0_cnt;
  bit[3:0] alligned_wstrb0_cnt;
  int index;
  int quotient_check;
  int quotient_check_1;
  int remainder_check;

  //-------------------------------------------------------
  // Step-1: for awsize == 0
  // Calculate the remainder by dividing awaddr and 2**awsize
  // that gives the nearest alligned address based on the 
  // remainder assert that particular strobe bit.
  //
  // Step-2: for awsize == 1
  // Calculate the quotient by dividing awaddr and 2**awsize
  // if quotient is alligned assert first 2 bits of strobes
  // else assert next 2 bits of strobes
  //
  //Step-3: for awsize == 2
  //Here you can assert all 4bits of strobes since it is a 
  //alligned address and all 4bits needs to pass
  //(addr ex: 0,4,8..)
  //-------------------------------------------------------
  //-------------------------------------------------------
  // Narrow Transfers for alligned address
  //-------------------------------------------------------
  req.wstrb.delete();
  for(int i = 0; i <= req.awlen; i++) begin
      req.wstrb.push_back(0); 
  end
  if(req.awaddr % 2**req.awsize == 0) begin
    awsize_0 = 4'b0001;
    awsize_1 = 4'b1111;
    remainder_check = req.awaddr % 4;
    `uvm_info("rem_check",$sformatf("remainder_check = %0d",remainder_check),UVM_HIGH)
    
    // Assigning the initial strobe values based on the size and address issued
    if(req.awsize == 0) begin
      if(remainder_check == 0) wstrb_local = 4'b0001; 
      if(remainder_check == 1) wstrb_local = 4'b0010; 
      if(remainder_check == 2) wstrb_local = 4'b0100; 
      if(remainder_check == 3) wstrb_local = 4'b1000; 
    end
   
    if(req.awsize == 1) begin 
      quotient_check_1 = req.awaddr / 2**req.awsize;
      if(quotient_check_1 % 2 == 0) begin
      wstrb_local = 4'b0011;
    end
    else begin
      wstrb_local = 4'b1100;
    end
    end
  
    if(req.awsize == 2) wstrb_local = 4'b1111;
    `uvm_info(get_type_name(), $sformatf("DEBUG_LOCAL :: wstrb_local =  %0b",wstrb_local), UVM_HIGH); 
    `uvm_info(get_type_name(), $sformatf("DEBUG_LOCL :: awsize =  %0d",req.awsize), UVM_HIGH); 
    
    wstrb_size_0_local = wstrb_local;

    //for loop to generate the strobe values based on strobe size
    for(int i=0;i<req.wstrb.size();i++) begin
      `uvm_info(get_type_name(),$sformatf("inside for loop of post randomize"),UVM_HIGH)
      
      if(req.awsize == 0) begin
        if(remainder_check == 0)begin
          if(i==0) begin
            req.wstrb[0] = wstrb_local;
            `uvm_info(get_type_name(), $sformatf("DEBUG_IN_LOOP :: wstrb[0] =  %0b",req.wstrb[0]), UVM_HIGH); 
          end 
          else begin
            // since remainder is 0 it will be in 1st(0) lane
            // so after every 4 transfers u need to assign wstrb(0)
            if(i%4 == 0) begin
              req.wstrb[i] = awsize_0;
              wstrb_size_0_local = awsize_0;
            end
            else begin
              wstrb_size_0_local = (wstrb_size_0_local << 2**req.awsize);
              req.wstrb[i] = wstrb_size_0_local;
            end
            `uvm_info(get_type_name(), $sformatf("DEBUG_IN_LOOP :: wstrb[%0d] =  %0b",i,req.wstrb[i]), UVM_HIGH); 
            `uvm_info(get_type_name(),$sformatf("outside for loop of post randomize"),UVM_HIGH)
          end
        end
        
        // since remainder is 1 it will be in 2nd(1) lane
        else if (remainder_check == 1) begin
          if(i==0) begin
            req.wstrb[0] = wstrb_local;
            `uvm_info(get_type_name(), $sformatf("DEBUG_IN_LOOP :: wstrb[0] =  %0b",req.wstrb[0]), UVM_HIGH); 
          end 
          else if(i == 1) begin
            req.wstrb[1] = req.wstrb[0] << i;
          end
          else if(i == 2) begin
            req.wstrb[2] = req.wstrb[0] << i;
            wstrb_size_0_local = awsize_0;
          end
          else begin 
            req.wstrb[i] = wstrb_size_0_local;
            wstrb_size_0_local = (wstrb_size_0_local << 2**req.awsize);
            alligned_wstrb0_cnt++;
            if(alligned_wstrb0_cnt == 4) begin
              // so after every 4 transfers u need to assign awsize_0
              wstrb_size_0_local = awsize_0;
              alligned_wstrb0_cnt = 0;
            end
          end
        end  
        
        else if (remainder_check == 2) begin
          if(i==0) begin
            req.wstrb[0] = wstrb_local;
            `uvm_info(get_type_name(), $sformatf("DEBUG_IN_LOOP :: wstrb[0] =  %0b",req.wstrb[0]), UVM_HIGH); 
          end 
          else if(i == 1) begin
            req.wstrb[1] = req.wstrb[0] << i;
            wstrb_size_0_local = awsize_0;
          end
          
          else begin 
            req.wstrb[i] = wstrb_size_0_local;
            wstrb_size_0_local = (wstrb_size_0_local << 2**req.awsize);
            alligned_wstrb0_cnt++;
            if(alligned_wstrb0_cnt == 4) begin
              wstrb_size_0_local = awsize_0;
              alligned_wstrb0_cnt = 0;
            end
          end
        end
        
        else if (remainder_check == 3) begin
          if(i==0) begin
            req.wstrb[0] = wstrb_local;
            wstrb_size_0_local = awsize_0;
            `uvm_info(get_type_name(), $sformatf("DEBUG_IN_LOOP :: wstrb[0] =  %0b",req.wstrb[0]), UVM_HIGH); 
          end 
          
          else begin 
            req.wstrb[i] = wstrb_size_0_local;
            wstrb_size_0_local = (wstrb_size_0_local << 2**req.awsize);
            alligned_wstrb0_cnt++;
            if(alligned_wstrb0_cnt == 4) begin
              wstrb_size_0_local = awsize_0;
              alligned_wstrb0_cnt = 0;
            end
          end
        end
      end
      
      else if(req.awsize == 1) begin
        if(quotient_check_1 % 2**req.awsize == 0) begin 
          if(i==0) begin
            req.wstrb[0] = wstrb_local;
            `uvm_info(get_type_name(), $sformatf("DEBUG_IN_LOOP :: wstrb[0] =  %0b",req.wstrb[0]), UVM_HIGH); 
          end 
          else begin
            if(i%2 == 0) begin
              req.wstrb[i] = {(wstrb_local << 2**req.awsize)^awsize_1};
            end
            else begin
              req.wstrb[i] = (wstrb_local << 2**req.awsize);
            end
          end
        end
        
        else begin
          if(i==0) begin
            req.wstrb[0] = wstrb_local;
            `uvm_info(get_type_name(), $sformatf("DEBUG_IN_LOOP :: wstrb[0] =  %0b",req.wstrb[0]), UVM_HIGH); 
          end 
          else begin
            if(i%2 == 0) begin
              req.wstrb[i] = wstrb_local;
            end
            else begin
              req.wstrb[i] = (wstrb_local >> 2**req.awsize);
            end
          end
        end
      end
      
      else if(req.awsize == 2) begin
        req.wstrb[i] = wstrb_local;
      end
    end
end


//-------------------------------------------------------
// Strobes for Unalligned transfers
//-------------------------------------------------------
if(req.awaddr % 2**req.awsize != 0) begin
  
  unallignd_wstrb0 = 4'b0001;
  unallignd_wstrb1 = 4'b0011;
  unallignd_wstrb2 = 4'b1111;
  
  quotient_check = req.awaddr / 2**req.awsize;
  
  if(req.awsize == 0) begin
    wstrb_local = 4'b0001;
  end
  if(req.awsize == 1) begin
    if(quotient_check%2 == 0) begin
      wstrb_local = 4'b0010;
    end
    else begin
      wstrb_local = 4'b1000;
    end
  end
  //in the 1st case why 3 bits made 1 becoz 
  //since addr is 1 if you pass only that address as high 
  //then in nxt lane it will start from addr 2 which is unalligned for size
  //so if u pass all 3 bits nxt transfer will strat from 4 which is alligned.
  if(req.awsize == 2) begin
    if(req.awaddr % 2**req.awsize == 1) wstrb_local = 4'b1110; 
    if(req.awaddr % 2**req.awsize == 2) wstrb_local = 4'b1100; 
    if(req.awaddr % 2**req.awsize == 3) wstrb_local = 4'b1000;
  end
  
  for(int i=0;i<req.wstrb.size();i++) begin
    if(req.awsize == 0) begin
      if(i == 0) begin
        req.wstrb[0] = wstrb_local;
      end
      else begin
        req.wstrb[i] = wstrb_local << 1;
        unallignd_wstrb0_cnt++;
        if(unallignd_wstrb0_cnt == 'd3) begin
          req.wstrb[i] = wstrb_local;
          unallignd_wstrb0_cnt = 0;
        end
      end
    end
    
    if(req.awsize == 1) begin
      if(i == 0) begin
        req.wstrb[0] = wstrb_local;
      end
      else if(i == 1) begin
        req.wstrb[i] = unallignd_wstrb1;
      end
      else begin
        if(i%2 == 0) begin
          req.wstrb[i] = unallignd_wstrb1 << 2;
        end
        else if(i%2 != 0) begin
          req.wstrb[i] = unallignd_wstrb1;
      end
    end
  end
  
  if(req.awsize == 2) begin
    if(i==0) begin
      req.wstrb[0] = wstrb_local;
    end
    else begin
      req.wstrb[i] = unallignd_wstrb2;
    end
   end
  end
end
return req;
endfunction : strobe_generation

`endif
