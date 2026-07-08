`ifndef AXI5_SCOREBOARD_INCLUDED_
`define AXI5_SCOREBOARD_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_scoreboard
// Scoreboard the data getting from monitor port that goes into the implementation port
//--------------------------------------------------------------------------------------------
class axi5_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(axi5_scoreboard)

  // Declaring handles for master tx and slave tx
  axi5_master_tx axi5_master_tx_h1;
  axi5_master_tx axi5_master_tx_h2;
  axi5_master_tx axi5_master_tx_h3;
  axi5_master_tx axi5_master_tx_h4;
  axi5_master_tx axi5_master_tx_h5;

  axi5_slave_tx axi5_slave_tx_h1;
  axi5_slave_tx axi5_slave_tx_h2;
  axi5_slave_tx axi5_slave_tx_h3;
  axi5_slave_tx axi5_slave_tx_h4;
  axi5_slave_tx axi5_slave_tx_h5;

  //Variable : axi5_master_analysis_fifo
  //Used to store the axi5_master_data
  uvm_tlm_analysis_fifo#(axi5_master_tx) axi5_master_read_address_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi5_master_tx) axi5_master_read_data_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi5_master_tx) axi5_master_write_address_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi5_master_tx) axi5_master_write_data_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi5_master_tx) axi5_master_write_response_analysis_fifo;
  
  //Variable : axi5_slave_analysis_fifo
  //Used to store the axi5_slave_data
  uvm_tlm_analysis_fifo#(axi5_slave_tx) axi5_slave_read_address_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi5_slave_tx) axi5_slave_read_data_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi5_slave_tx) axi5_slave_write_address_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi5_slave_tx) axi5_slave_write_data_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi5_slave_tx) axi5_slave_write_response_analysis_fifo;

  //master tx_count
  int axi5_master_tx_awaddr_count;
  //slave tx count
  int axi5_slave_tx_awaddr_count;
  
  //master tx_count
  int axi5_master_tx_wdata_count;
  //slave tx count
  int axi5_slave_tx_wdata_count;
  
  //master tx_count
  int axi5_master_tx_bresp_count;
  //slave tx count
  int axi5_slave_tx_bresp_count;
  
  //master tx_count
  int axi5_master_tx_araddr_count;
  //slave tx count
  int axi5_slave_tx_araddr_count;
  
  //master tx_count
  int axi5_master_tx_rdata_count;
  //slave tx count
  int axi5_slave_tx_rdata_count;
  
  //master tx_count
  int axi5_master_tx_rresp_count;
  //slave tx count
  int axi5_slave_tx_rresp_count;
  
  semaphore write_address_key;
  semaphore write_data_key;
  semaphore write_response_key;
  semaphore read_address_key;
  semaphore read_data_key;


  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_scoreboard", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual function void start_of_simulation_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task axi5_write_address();
  extern virtual task axi5_write_data();
  extern virtual task axi5_write_response();
  extern virtual task axi5_read_address();
  extern virtual task axi5_read_data();
  extern virtual function void check_phase (uvm_phase phase);
  extern virtual function void report_phase(uvm_phase phase);

endclass : axi5_scoreboard

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi5_scoreboard
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi5_scoreboard::new(string name = "axi5_scoreboard",
                                 uvm_component parent = null);
  super.new(name, parent);
  axi5_master_write_address_analysis_fifo = new("axi5_master_write_address_analysis_fifo",this);
  axi5_master_write_data_analysis_fifo = new("axi5_master_write_data_analysis_fifo",this);
  axi5_master_write_response_analysis_fifo= new("axi5_master_write_response_analysis_fifo",this);
  axi5_master_read_address_analysis_fifo = new("axi5_master_read_address_analysis_fifo",this);
  axi5_master_read_data_analysis_fifo = new("axi5_master_read_data_analysis_fifo",this);
 
  axi5_slave_write_address_analysis_fifo = new("axi5_slave_write_address_analysis_fifo",this);
  axi5_slave_write_data_analysis_fifo = new("axi5_slave_write_data_analysis_fifo",this);
  axi5_slave_write_response_analysis_fifo= new("axi5_slave_write_response_analysis_fifo",this);
  axi5_slave_read_address_analysis_fifo = new("axi5_slave_read_address_analysis_fifo",this);
  axi5_slave_read_data_analysis_fifo = new("axi5_slave_read_data_analysis_fifo",this);

  write_address_key = new(1);
  write_data_key = new(1);
  write_response_key = new(1);
  read_address_key = new(1);
  read_data_key = new(1);

endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_scoreboard::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: connect_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_scoreboard::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase

//--------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_scoreboard::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
endfunction  : end_of_elaboration_phase

//--------------------------------------------------------------------------------------------
// Function: start_of_simulation_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_scoreboard::start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);
endfunction : start_of_simulation_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// All the comparision are done
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi5_scoreboard::run_phase(uvm_phase phase);

  super.run_phase(phase);

  fork
    axi5_write_address();
    axi5_write_data();
    axi5_write_response();
    axi5_read_address();
    axi5_read_data();
  join

endtask : run_phase

//--------------------------------------------------------------------------------------------
// Task: axi5_write_address
// Gets the master and slave write address and send it to the write address comparision task
//--------------------------------------------------------------------------------------------
task axi5_scoreboard::axi5_write_address();

  forever begin
    write_address_key.get(1);
    axi5_master_write_address_analysis_fifo.get(axi5_master_tx_h1);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_master_write_address_channel \n%s",axi5_master_tx_h1.sprint()),UVM_LOW)
    axi5_slave_write_address_analysis_fifo.get(axi5_slave_tx_h1);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_slave_write_address_channel \n%s",axi5_slave_tx_h1.sprint()),UVM_LOW)

    axi5_master_tx_h1.compare_mode = CHECK_WRITE_ADDRESS;
    axi5_slave_tx_h1.compare_mode = CHECK_WRITE_ADDRESS;
    if(axi5_master_tx_h1.do_compare(axi5_slave_tx_h1,uvm_default_comparer)) begin
      `uvm_info("COMPARE_AW","Write Address comparision PASSED",UVM_HIGH)
    end
    else begin
      `uvm_error("COMPARE_AW","Write Address comparision FAILED")
    end
    
    axi5_master_tx_awaddr_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_master_write_address_channel count \n %0d",axi5_master_tx_awaddr_count),UVM_HIGH)
    axi5_slave_tx_awaddr_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_slave_write_address_channel count \n %0d",axi5_slave_tx_awaddr_count),UVM_HIGH)
    write_address_key.put(1);
  end

endtask : axi5_write_address

//--------------------------------------------------------------------------------------------
// Task: axi5_write_data
// Gets the master and slave write data and send it to the write data comparision task
//--------------------------------------------------------------------------------------------
task axi5_scoreboard::axi5_write_data();

  forever begin
    write_data_key.get(1);
    axi5_master_write_data_analysis_fifo.get(axi5_master_tx_h2);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_master_write_data_channel \n%s",axi5_master_tx_h2.sprint()),UVM_HIGH)
    axi5_slave_write_data_analysis_fifo.get(axi5_slave_tx_h2);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_slave_write_data_channel \n%s",axi5_slave_tx_h2.sprint()),UVM_HIGH)

    axi5_master_tx_h2.compare_mode = CHECK_WRITE_DATA;
    axi5_slave_tx_h2.compare_mode = CHECK_WRITE_DATA;
    if(axi5_master_tx_h2.do_compare(axi5_slave_tx_h2,uvm_default_comparer)) begin
      `uvm_info("COMPARE_WD","Write Data comparision PASSED",UVM_HIGH)
    end
    else begin
      `uvm_error("COMPARE_WD","Write Data comparision FAILED")
    end

    axi5_master_tx_wdata_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_master_write_data_channel count \n %0d",axi5_master_tx_wdata_count),UVM_HIGH)
    axi5_slave_tx_wdata_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_slave_write_data_channel count \n %0d",axi5_slave_tx_wdata_count),UVM_HIGH)
    write_data_key.put(1);
  end

endtask : axi5_write_data

//--------------------------------------------------------------------------------------------
// Task: axi5_write_response
// Gets the master and slave write response and send it to the write response comparision task
//--------------------------------------------------------------------------------------------
task axi5_scoreboard::axi5_write_response();

  forever begin
    write_response_key.get(1);
    axi5_master_write_response_analysis_fifo.get(axi5_master_tx_h3);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_master_write_response \n%s",axi5_master_tx_h3.sprint()),UVM_HIGH)
    axi5_slave_write_response_analysis_fifo.get(axi5_slave_tx_h3);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_slave_write_response \n%s",axi5_slave_tx_h3.sprint()),UVM_HIGH)

    axi5_master_tx_h3.compare_mode = CHECK_WRITE_RESP;
    axi5_slave_tx_h3.compare_mode = CHECK_WRITE_RESP;
    if(axi5_master_tx_h3.do_compare(axi5_slave_tx_h3,uvm_default_comparer)) begin
      `uvm_info("COMPARE_B","Write Response comparision PASSED",UVM_HIGH)
    end
    else begin
      `uvm_error("COMPARE_B","Write Response comparision FAILED")
    end

    axi5_master_tx_bresp_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_master_write_response_channel count \n %0d",axi5_master_tx_bresp_count),UVM_HIGH)
    axi5_slave_tx_bresp_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_slave_write_response_channel count \n %0d",axi5_slave_tx_bresp_count),UVM_HIGH)
    write_response_key.put(1);
  end

endtask : axi5_write_response

//--------------------------------------------------------------------------------------------
// Task: axi5_read_address
// Gets the master and slave read address and send it to the read address comparision task
//--------------------------------------------------------------------------------------------
task axi5_scoreboard::axi5_read_address();

  forever begin
    read_address_key.get(1);
    axi5_master_read_address_analysis_fifo.get(axi5_master_tx_h4);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_master_read_address_channel \n%s",axi5_master_tx_h4.sprint()),UVM_HIGH)
    axi5_slave_read_address_analysis_fifo.get(axi5_slave_tx_h4);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_slave_read_address_channel \n%s",axi5_slave_tx_h4.sprint()),UVM_HIGH)

    axi5_master_tx_h4.compare_mode = CHECK_READ_ADDRESS;
    axi5_slave_tx_h4.compare_mode = CHECK_READ_ADDRESS;
    if(axi5_master_tx_h4.do_compare(axi5_slave_tx_h4,uvm_default_comparer)) begin
      `uvm_info("COMPARE_AR","Read Address comparision PASSED",UVM_HIGH)
    end
    else begin
      `uvm_error("COMPARE_AR","Read Address comparision FAILED")
    end
    
    axi5_master_tx_araddr_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_master_read_address_channel count \n %0d",axi5_master_tx_araddr_count),UVM_HIGH)
    axi5_slave_tx_araddr_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_slave_read_address_channel count \n %0d",axi5_slave_tx_araddr_count),UVM_HIGH)
    read_address_key.put(1);
  end

endtask : axi5_read_address

//--------------------------------------------------------------------------------------------
// Task: axi5_read_data
// Gets the master and slave read data and send it to the read data comparision task
//--------------------------------------------------------------------------------------------
task axi5_scoreboard::axi5_read_data();

  forever begin
    read_data_key.get(1);
    axi5_master_read_data_analysis_fifo.get(axi5_master_tx_h5);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_master_read_data_channel \n%s",axi5_master_tx_h5.sprint()),UVM_HIGH)
    axi5_slave_read_data_analysis_fifo.get(axi5_slave_tx_h5);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_slave_read_data_channel \n%s",axi5_slave_tx_h5.sprint()),UVM_HIGH)

    axi5_master_tx_h5.compare_mode = CHECK_READ_DATA;
    axi5_slave_tx_h5.compare_mode = CHECK_READ_DATA;
    if(axi5_master_tx_h5.do_compare(axi5_slave_tx_h5,uvm_default_comparer)) begin
      `uvm_info("COMPARE_R","Read Data comparision PASSED",UVM_HIGH)
    end
    else begin
      `uvm_error("COMPARE_R","Read Data comparision FAILED")
    end

    axi5_master_tx_rdata_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_master_read_data_channel count \n %0d",axi5_master_tx_rdata_count),UVM_HIGH)
    axi5_slave_tx_rdata_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_slave_read_data_channel count \n %0d",axi5_slave_tx_rdata_count),UVM_HIGH)
    axi5_master_tx_rresp_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_master_read_response_channel count \n %0d",axi5_master_tx_rresp_count),UVM_HIGH)
    axi5_slave_tx_rresp_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi5_slave_read_response_channel count \n %0d",axi5_slave_tx_rresp_count),UVM_HIGH)
    read_data_key.put(1);
  end

endtask : axi5_read_data

//--------------------------------------------------------------------------------------------
// Function: check_phase
// Display the result of simulation
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_scoreboard::check_phase(uvm_phase phase);
  super.check_phase(phase);

  `uvm_info(get_type_name(),$sformatf("--\n----------------------------------------------SCOREBOARD CHECK PHASE---------------------------------------"),UVM_HIGH) 
  
  `uvm_info (get_type_name(),$sformatf(" Scoreboard Check Phase is starting"),UVM_HIGH); 
  
  //--------------------------------------------------------------------------------------------
  // 1.Check if tatol number of master and slave packets are same for each channel
  //   A non-zero value indicates that the comparisions never happened and throw error
  // 2.Initial count of the failed count is zero
  //   If the failed count is more than 0 it means comparision is failed and gives error  
  //--------------------------------------------------------------------------------------------

  //-------------------------------------------------------
  // Write_Address_Channel comparision
  // Write_Data_Channel comparision
  // Write_Response_Channel comparision
  //-------------------------------------------------------

  if((axi5_master_tx_awaddr_count != axi5_master_tx_wdata_count) && (axi5_master_tx_wdata_count != axi5_master_tx_bresp_count)) begin
    `uvm_error (get_type_name(), $sformatf ("Total number of packets from three channel of write are not same"));
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("Total number of packets from three channel of write are same, Number: %0d",axi5_master_tx_awaddr_count),UVM_HIGH);
  end
 
  //-------------------------------------------------------
  // Read_Address_Channel comparision
  // Read_Data_Channel comparision
  //-------------------------------------------------------
  if((axi5_master_tx_araddr_count != axi5_master_tx_rdata_count) && (axi5_master_tx_rdata_count != axi5_master_tx_rresp_count)) begin
    `uvm_error (get_type_name(), $sformatf ("Total number of packets from two channel of read are not same"));
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("Total number of packets from two channel of read are same, Number: %0d",axi5_master_tx_araddr_count),UVM_HIGH);
  end
  //--------------------------------------------------------------------------------------------
  // 2.Check if master packets received are same as slave packets received
  //   To Make sure that we have equal number of master and slave packets
  //--------------------------------------------------------------------------------------------
  
  //--------------------------------------------------------------------------------------------
  // 3.Analysis fifos must be zero - This will indicate that all the packets have been compared
  //   This is to make sure that we have taken all packets from both FIFOs and made the comparisions
  //--------------------------------------------------------------------------------------------
  //!!!! recommend use used() instead of size() to check the FIFO depth as used() will give the number of elements in the FIFO while size() will give the total capacity of the FIFO
  if (axi5_master_write_address_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi5 Master write address analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi5_master_write_address_analysis_fifo:%0d",axi5_master_write_address_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi5 Master write address analysis FIFO is not empty"));
  end

  if (axi5_master_write_data_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi5 Master write data analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi5_master_write_data_analysis_fifo:%0d",axi5_master_write_data_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi5 Master write data analysis FIFO is not empty"));
  end

  if (axi5_master_write_response_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi5 Master write response analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi5_master_write_response_analysis_fifo:%0d",axi5_master_write_response_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi5 Master write response analysis FIFO is not empty"));
  end
 
  if (axi5_master_read_address_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi5 Master read address analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi5_master_read_address_analysis_fifo:%0d",axi5_master_read_address_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi5 Master read address analysis FIFO is not empty"));
  end

  if (axi5_master_read_data_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi5 Master read data analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi5_master_read_data_analysis_fifo:%0d",axi5_master_read_data_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi5 Master read data analysis FIFO is not empty"));
  end

  if (axi5_slave_write_address_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi5 slave write address analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi5_slave_write_address_analysis_fifo:%0d",axi5_slave_write_address_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi5 slave write address analysis FIFO is not empty"));
  end

  if (axi5_slave_write_data_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi5 slave write data analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi5_slave_write_data_analysis_fifo:%0d",axi5_slave_write_data_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi5 slave write data analysis FIFO is not empty"));
  end

  if (axi5_slave_write_response_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi5 slave write response analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi5_slave_write_response_analysis_fifo:%0d",axi5_slave_write_response_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi5 slave write response analysis FIFO is not empty"));
  end
 
  if (axi5_slave_read_address_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi5 slave read address analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi5_slave_read_address_analysis_fifo:%0d",axi5_slave_read_address_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi5 slave read address analysis FIFO is not empty"));
  end

  if (axi5_slave_read_data_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi5 slave read data analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi5_slave_read_data_analysis_fifo:%0d",axi5_slave_read_data_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi5 slave read data analysis FIFO is not empty"));
  end

  `uvm_info(get_type_name(),$sformatf("--\n----------------------------------------------END OF SCOREBOARD CHECK PHASE---------------------------------------"),UVM_HIGH)

  `uvm_info(get_type_name(),$sformatf("--\n----------------------------------------------END OF SCOREBOARD CHECK PHASE---------------------------------------"),UVM_HIGH)

endfunction : check_phase

//--------------------------------------------------------------------------------------------
// Function: report_phase
// Display the result of simulation
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi5_scoreboard::report_phase(uvm_phase phase);
  super.report_phase(phase);
  
  $display(" ");
  $display("-------------------------------------------- ");
  $display("SCOREBOARD REPORT PHASE");
  $display("-------------------------------------------- ");
  $display(" ");

  $display(" ");
  $display("-------------------------------------------- ");
  $display("SCOREBOARD WRITE ADDRESS PACKETS");
  $display("-------------------------------------------- ");
  $display(" ");
    `uvm_info(get_type_name(),$sformatf("scoreboard's write address packets count  from master   \n %0d",axi5_master_tx_awaddr_count),UVM_HIGH)
    `uvm_info(get_type_name(),$sformatf("scoreboard's write address packets count  from slave    \n %0d",axi5_slave_tx_awaddr_count),UVM_HIGH)
    //`uvm_info (get_type_name(),$sformatf("Total no. of byte wise awaddr verified comparisions:%0d",byte_data_cmp_verified_awaddr_count ),UVM_NONE);
  //`uvm_info (get_type_name(),$sformatf("Total no. of byte wise awaddr failed comparisions:%0d",byte_data_cmp_failed_awaddr_count ),UVM_NONE);
 
  $display(" ");
  $display("-------------------------------------------- ");
  $display("SCOREBOARD WRITE DATA PACKETS");
  $display("-------------------------------------------- ");
  $display(" ");
    `uvm_info(get_type_name(),$sformatf("scoreboard's  write data packets count from master \n %0d",axi5_master_tx_wdata_count),UVM_HIGH)
    `uvm_info(get_type_name(),$sformatf("scoreboard's  write data packets count from slave   \n %0d",axi5_slave_tx_wdata_count),UVM_HIGH)
  
  $display(" ");
  $display("-------------------------------------------- ");
  $display("SCOREBOARD WRITE RESPONSE PACKETS");
  $display("-------------------------------------------- ");
  $display(" ");
    `uvm_info(get_type_name(),$sformatf("scoreboard's write response packets count from master \n %0d",axi5_master_tx_bresp_count),UVM_HIGH)
    `uvm_info(get_type_name(),$sformatf("scoreboard's write response packets count from slave  \n %0d",axi5_slave_tx_bresp_count),UVM_HIGH)
  

  
  $display("-------------------------------------------- ");
  $display("READ_ADDRESS_PHASE");
  $display("-------------------------------------------- ");
  
  
  $display("READ_DATA_PHASE");
 
  $display(" ");
  $display("-------------------------------------------- ");
  $display("SCOREBOARD READ ADDRESS PACKETS");
  $display("-------------------------------------------- ");
  $display(" ");
    `uvm_info(get_type_name(),$sformatf("scoreboard's read address packets count from master \n %0d",axi5_master_tx_araddr_count),UVM_HIGH)
    `uvm_info(get_type_name(),$sformatf("scoreboard's read address packets count from slave  \n %0d",axi5_slave_tx_araddr_count),UVM_HIGH)
  
  $display(" ");
  $display("-------------------------------------------- ");
  $display("SCOREBOARD READ DATA PACKETS");
  $display("-------------------------------------------- ");
  $display(" ");
    `uvm_info(get_type_name(),$sformatf("scoreboard's  read data packets count from master \n %0d",axi5_master_tx_rdata_count),UVM_HIGH)
    `uvm_info(get_type_name(),$sformatf("scoreboard's  read data packets count from slave  \n %0d",axi5_slave_tx_rdata_count),UVM_HIGH)
  
  $display(" ");
  $display("-------------------------------------------- ");
  $display("SCOREBOARD READ RESPONSE PACKETS");
  $display("-------------------------------------------- ");
  $display(" ");
    `uvm_info(get_type_name(),$sformatf("scoreboard's read response packets count from master \n %0d",axi5_master_tx_rresp_count),UVM_HIGH)
    `uvm_info(get_type_name(),$sformatf("scoreboard's read response packets count from slave   \n %0d",axi5_slave_tx_rresp_count),UVM_HIGH)

endfunction : report_phase

`endif

