`ifndef AXI5_MASTER_SEQ_ITEM_CONVERTER_INCLUDED_
`define AXI5_MASTER_SEQ_ITEM_CONVERTER_INCLUDED_

//--------------------------------------------------------------------------------------------
// class : axi5 master_seq_item_converter
// Description:
// class converting seq_item transactions into struct data items and viceversa
//--------------------------------------------------------------------------------------------

class axi5_master_seq_item_converter extends uvm_object;
  `uvm_object_utils(axi5_master_seq_item_converter)
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi5_master_seq_item_converter");
  extern static function void from_write_class(input axi5_master_tx input_conv_h,output axi5_write_transfer_char_s output_conv_h);
  extern static function void from_read_class(input axi5_master_tx input_conv_h,output axi5_read_transfer_char_s output_conv_h);
  extern static function void to_write_class(input axi5_write_transfer_char_s input_conv_h,output axi5_master_tx output_conv_h);
  extern static function void to_read_class(input axi5_read_transfer_char_s input_conv_h,output axi5_master_tx output_conv_h);
  extern static function void to_write_addr_data_class(input axi5_master_tx waddr_packet, input axi5_write_transfer_char_s input_conv_h,output axi5_master_tx output_conv_h);
  extern static function void to_write_addr_data_resp_class(input axi5_master_tx waddr_data_packet, input axi5_write_transfer_char_s input_conv_h,output axi5_master_tx output_conv_h);
  extern static function void to_read_addr_data_class(input axi5_master_tx raddr_packet, input axi5_read_transfer_char_s input_conv_h,output axi5_master_tx output_conv_h);
  extern function void do_print(uvm_printer printer);

endclass : axi5_master_seq_item_converter

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi5_master_seq_item_converter
//--------------------------------------------------------------------------------------------
function axi5_master_seq_item_converter::new(string name = "axi5_master_seq_item_converter");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: from_write_class
// Converting seq_item transactions into struct data items
//
// Parameters:
// name - axi5_master_tx, axi5_write_transfer_char_s
//--------------------------------------------------------------------------------------------

function void axi5_master_seq_item_converter::from_write_class( input axi5_master_tx input_conv_h, output axi5_write_transfer_char_s output_conv_h);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("----------------------------------------------------------------------"),UVM_HIGH);
 $cast(output_conv_h.awid,input_conv_h.awid); 
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting awid =  %b",output_conv_h.awid),UVM_HIGH);

  $cast(output_conv_h.awlen,input_conv_h.awlen);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting awlen =  %b",output_conv_h.awlen),UVM_HIGH);

  $cast(output_conv_h.awsize,input_conv_h.awsize);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After randomizing awsize =  %b",output_conv_h.awsize),UVM_HIGH);

  $cast(output_conv_h.awburst,input_conv_h.awburst); 
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting awburst =  %b",output_conv_h.awburst),UVM_HIGH);

  $cast(output_conv_h.awlock,input_conv_h.awlock);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting awlock =  %b",output_conv_h.awlock),UVM_HIGH);

  $cast(output_conv_h.awregion,input_conv_h.awregion);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting awregion =  %b",output_conv_h.awregion),UVM_HIGH);

  $cast(output_conv_h.awcache,input_conv_h.awcache);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After randomizing awcache =  %b",output_conv_h.awcache),UVM_HIGH);

  $cast(output_conv_h.awprot,input_conv_h.awprot);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After randomizing awprot =  %b",output_conv_h.awprot),UVM_HIGH);

  $cast(output_conv_h.bid,input_conv_h.bid);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting bid =  %b",output_conv_h.bid),UVM_HIGH);

  $cast(output_conv_h.bresp,input_conv_h.bresp);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting bresp =  %b",output_conv_h.bresp),UVM_HIGH);
 
  output_conv_h.buser = input_conv_h.buser;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting buser =  %b",output_conv_h.buser),UVM_HIGH);

  output_conv_h.awaddr = input_conv_h.awaddr;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting awaddr =  %0h",output_conv_h.awaddr),UVM_HIGH);

  output_conv_h.awqos = input_conv_h.awqos;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting awqos =  %0h",output_conv_h.awqos),UVM_HIGH);

  //AXI5 write address additional signals
  output_conv_h.awakeup     = input_conv_h.awakeup;
  output_conv_h.awdomain    = input_conv_h.awdomain;
  output_conv_h.awinner     = input_conv_h.awinner;
  output_conv_h.awchid      = input_conv_h.awchid;
  output_conv_h.awchidvalid = input_conv_h.awchidvalid;

  foreach(input_conv_h.wdata[i]) begin
    if(input_conv_h.wdata[i] != 0)begin
      output_conv_h.wdata[i] = input_conv_h.wdata[i];
      `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wdata =  %0p",output_conv_h.wdata),UVM_HIGH);
    end
  end

  foreach(input_conv_h.wdata[i]) begin
    if(input_conv_h.wdata[i] != 0)begin
      output_conv_h.wstrb[i] = input_conv_h.wstrb[i];
      `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wstrb = %0p",output_conv_h.wstrb[i]),UVM_HIGH);
    end
  end

  output_conv_h.wlast = input_conv_h.wlast;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wlast =  %0h",output_conv_h.wlast),UVM_HIGH);

  output_conv_h.wuser = input_conv_h.wuser;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wuser =  %0h",output_conv_h.wuser),UVM_HIGH);

  output_conv_h.no_of_wait_states = input_conv_h.no_of_wait_states;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting no_wait_states =  %0d",output_conv_h.no_of_wait_states),UVM_HIGH);

  output_conv_h.wait_count_write_address_channel =input_conv_h.wait_count_write_address_channel ;
  output_conv_h.wait_count_write_data_channel =input_conv_h.wait_count_write_data_channel ;
  output_conv_h.wait_count_write_response_channel =input_conv_h.wait_count_write_response_channel ;

endfunction : from_write_class


//--------------------------------------------------------------------------------------------
// Function: from_read_class
// Converting seq_item transactions into struct data items
//
// Parameters:
// name - axi5_master_tx, axi5_read_transfer_char_s
//--------------------------------------------------------------------------------------------

function void axi5_master_seq_item_converter::from_read_class( input axi5_master_tx input_conv_h, output axi5_read_transfer_char_s output_conv_h);

  $cast(output_conv_h.arid,input_conv_h.arid);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arid =  %b",output_conv_h.arid),UVM_HIGH);

  $cast(output_conv_h.arlen,input_conv_h.arlen);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After conrveting arlen =  %b",output_conv_h.arlen),UVM_HIGH);

  $cast(output_conv_h.arsize,input_conv_h.arsize);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arsize =  %b",output_conv_h.arsize),UVM_HIGH);

  $cast(output_conv_h.arburst,input_conv_h.arburst);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arburst =  %b",output_conv_h.arburst),UVM_HIGH);

  $cast(output_conv_h.arlock,input_conv_h.arlock);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arlock =  %b",output_conv_h.arlock),UVM_HIGH);

  $cast(output_conv_h.arcache,input_conv_h.arcache);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arcache =  %b",output_conv_h.arcache),UVM_HIGH);

  $cast(output_conv_h.arprot,input_conv_h.arprot);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arprot =  %b",output_conv_h.arprot),UVM_HIGH);

  $cast(output_conv_h.rresp,input_conv_h.rresp);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting rresp =  %b",output_conv_h.rresp),UVM_HIGH);
  
  output_conv_h.araddr = input_conv_h.araddr;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting araddr =  %0h",output_conv_h.araddr),UVM_HIGH);

  output_conv_h.arqos = input_conv_h.arqos;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arqos =  %0h",output_conv_h.arqos),UVM_HIGH);

  output_conv_h.aruser = input_conv_h.aruser;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting aruser =  %0h",output_conv_h.aruser),UVM_HIGH);

  output_conv_h.arregion = input_conv_h.arregion;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arregion =  %0h",output_conv_h.arregion),UVM_HIGH);

  //AXI5 read address additional signals
  output_conv_h.ardomain    = input_conv_h.ardomain;
  output_conv_h.arinner     = input_conv_h.arinner;
  output_conv_h.archid      = input_conv_h.archid;
  output_conv_h.archidvalid = input_conv_h.archidvalid;
  output_conv_h.arcmdlink   = input_conv_h.arcmdlink;

  $cast(output_conv_h.rid,input_conv_h.rid);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting rid =  %b",output_conv_h.rid),UVM_HIGH);

  foreach(input_conv_h.rdata[i]) begin
    if(input_conv_h.rdata[i] != 0)begin
      output_conv_h.rdata[i] = input_conv_h.rdata[i];
      `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting rdata = %0p",output_conv_h.rdata[i]),UVM_HIGH);
    end
  end

  output_conv_h.ruser = input_conv_h.ruser;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting ruser =  %0b",output_conv_h.ruser),UVM_HIGH);

  output_conv_h.no_of_wait_states = input_conv_h.no_of_wait_states;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting no_wait_states =  %0d",output_conv_h.no_of_wait_states),UVM_HIGH);

  output_conv_h.wait_count_read_address_channel =input_conv_h.wait_count_read_address_channel ;
  output_conv_h.wait_count_read_data_channel =input_conv_h.wait_count_read_data_channel ;

  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("----------------------------------------------------------------------"),UVM_HIGH);
  
endfunction : from_read_class  

//--------------------------------------------------------------------------------------------
// Function: to_write_class
// Converting struct data items into seq_item transactions
//
// Parameters:
// name - axi5_master_tx, axi5_write_transfer_char_s
//--------------------------------------------------------------------------------------------
function void axi5_master_seq_item_converter::to_write_class( input axi5_write_transfer_char_s
  input_conv_h, output axi5_master_tx output_conv_h);
  output_conv_h = new();

  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("----------------------------------------------------------------------"),UVM_HIGH);
 

  output_conv_h.tx_type = WRITE; 

  $cast(output_conv_h.awid,input_conv_h.awid); 
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting awid =  %b",output_conv_h.awid),UVM_HIGH);

  $cast(output_conv_h.awlen,input_conv_h.awlen);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting awlen =  %b",output_conv_h.awlen),UVM_HIGH);

  $cast(output_conv_h.awsize,input_conv_h.awsize);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After randomizing awsize =  %b",output_conv_h.awsize),UVM_HIGH);

  $cast(output_conv_h.awburst,input_conv_h.awburst); 
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting awburst =  %b",output_conv_h.awburst),UVM_HIGH);

  $cast(output_conv_h.awlock,input_conv_h.awlock);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting awlock =  %b",output_conv_h.awlock),UVM_HIGH);

    $cast(output_conv_h.awregion,input_conv_h.awregion);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting awregion =  %b",output_conv_h.awregion),UVM_HIGH);

  $cast(output_conv_h.awcache,input_conv_h.awcache);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After randomizing awcache =  %b",output_conv_h.awcache),UVM_HIGH);

  $cast(output_conv_h.awprot,input_conv_h.awprot);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After randomizing awprot =  %b",output_conv_h.awprot),UVM_HIGH);

  output_conv_h.awaddr = input_conv_h.awaddr;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting awaddr =  %0h",output_conv_h.awaddr),UVM_HIGH);

  output_conv_h.awqos = input_conv_h.awqos;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting awqos =  %0h",output_conv_h.awqos),UVM_HIGH);

  //AXI5 write address additional signals
  output_conv_h.awakeup     = input_conv_h.awakeup;
  output_conv_h.awdomain    = input_conv_h.awdomain;
  output_conv_h.awinner     = input_conv_h.awinner;
  output_conv_h.awchid      = input_conv_h.awchid;
  output_conv_h.awchidvalid = input_conv_h.awchidvalid;

  output_conv_h.wait_count_write_address_channel = input_conv_h.wait_count_write_address_channel;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wait_count_write_address_channel =  %0h",output_conv_h.wait_count_write_address_channel),UVM_HIGH);

  foreach(input_conv_h.wdata[i]) begin
    if(input_conv_h.wdata[i] != 0)begin
      output_conv_h.wdata.push_front(input_conv_h.wdata[i]);
      `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wdata[%0d] =  %0h",i,output_conv_h.wdata[i]),UVM_HIGH);
    end
  end

  foreach(input_conv_h.wdata[i]) begin
    if(input_conv_h.wdata[i] != 0)begin
      output_conv_h.wstrb.push_front(input_conv_h.wstrb[i]);
      `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wstrb[%0d] =  %0d",i,output_conv_h.wstrb[i]),UVM_HIGH);
    end
  end

  output_conv_h.wlast = input_conv_h.wlast;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wlast =  %0h",output_conv_h.wlast),UVM_HIGH);

  output_conv_h.wuser = input_conv_h.wuser;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wuser =  %0h",output_conv_h.wuser),UVM_HIGH);

  output_conv_h.wait_count_write_data_channel = input_conv_h.wait_count_write_data_channel;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wait_count_write_data_channel =  %0h",output_conv_h.wait_count_write_data_channel),UVM_HIGH);

  $cast(output_conv_h.bid,input_conv_h.bid);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting bid =  %b",output_conv_h.bid),UVM_HIGH);

  $cast(output_conv_h.bresp,input_conv_h.bresp);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting bresp =  %b",output_conv_h.bresp),UVM_HIGH);

  output_conv_h.wait_count_write_response_channel = input_conv_h.wait_count_write_response_channel;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wait_count_write_response_channel = %0h",output_conv_h.wait_count_write_response_channel),UVM_HIGH);

endfunction : to_write_class

//--------------------------------------------------------------------------------------------
// Function: to_read_class
// Converting struct data items into seq_item transactions
//
// Parameters:
// name - axi5_master_tx, axi5_read_transfer_char_s
//--------------------------------------------------------------------------------------------
function void axi5_master_seq_item_converter::to_read_class( input axi5_read_transfer_char_s
  input_conv_h, output axi5_master_tx output_conv_h);

  output_conv_h = new();

  $cast(output_conv_h.arid,input_conv_h.arid);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arid =  %b",output_conv_h.arid),UVM_HIGH);

  $cast(output_conv_h.arlen,input_conv_h.arlen);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arlen =  %b",output_conv_h.arlen),UVM_HIGH);

  output_conv_h.araddr = input_conv_h.araddr;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting araddr =  %0h",output_conv_h.araddr),UVM_HIGH);

  output_conv_h.arqos = input_conv_h.arqos;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arqos =  %0h",output_conv_h.arqos),UVM_HIGH);

  $cast(output_conv_h.arsize,input_conv_h.arsize);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arsize =  %b",output_conv_h.arsize),UVM_HIGH);

  $cast(output_conv_h.arburst,input_conv_h.arburst);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arburst =  %b",output_conv_h.arburst),UVM_HIGH);

  $cast(output_conv_h.arlock,input_conv_h.arlock);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arlock =  %b",output_conv_h.arlock),UVM_HIGH);

  $cast(output_conv_h.arcache,input_conv_h.arcache);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arcache =  %b",output_conv_h.arcache),UVM_HIGH);

  $cast(output_conv_h.arprot,input_conv_h.arprot);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting arprot =  %b",output_conv_h.arprot),UVM_HIGH);

  //AXI5 read address additional signals
  output_conv_h.ardomain    = input_conv_h.ardomain;
  output_conv_h.arinner     = input_conv_h.arinner;
  output_conv_h.archid      = input_conv_h.archid;
  output_conv_h.archidvalid = input_conv_h.archidvalid;
  output_conv_h.arcmdlink   = input_conv_h.arcmdlink;
  //AXI5 read data poison (first beat)
  output_conv_h.rpoison     = input_conv_h.rpoison[0];

  output_conv_h.wait_count_read_address_channel = input_conv_h.wait_count_read_address_channel;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wait_count_read_address_channel =  %0h",output_conv_h.wait_count_read_address_channel),UVM_HIGH);

  $cast(output_conv_h.rresp,input_conv_h.rresp);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting rresp =  %b",output_conv_h.rresp),UVM_HIGH);
  
  $cast(output_conv_h.rid,input_conv_h.rid);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting rid =  %b",output_conv_h.rid),UVM_HIGH);

  foreach(input_conv_h.rdata[i]) begin
    if(input_conv_h.rdata[i] != 'h0)begin
      output_conv_h.rdata.push_front(input_conv_h.rdata[i]);
      `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting rdata =  %0h",output_conv_h.rdata[i]),UVM_HIGH);
    end
  end

  output_conv_h.wait_count_read_data_channel = input_conv_h.wait_count_read_data_channel;
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wait_count_read_data_channel =  %0h",output_conv_h.wait_count_read_data_channel),UVM_HIGH);

  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("----------------------------------------------------------------------"),UVM_HIGH);
endfunction : to_read_class

//--------------------------------------------------------------------------------------------
// Function: to_write_addr_data_class
// Converting struct data items into seq_item transactions
//
// Parameters:
// name - axi5_master_tx, axi5_write_transfer_char_s
//--------------------------------------------------------------------------------------------
function void axi5_master_seq_item_converter::to_write_addr_data_class(input axi5_master_tx waddr_packet, input axi5_write_transfer_char_s input_conv_h, output axi5_master_tx output_conv_h);
  output_conv_h = new();

  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("----------------------------------------------------------------------"),UVM_HIGH);
 

  output_conv_h.tx_type = WRITE; 

  $cast(output_conv_h.awid,waddr_packet.awid); 
  $cast(output_conv_h.awlen,waddr_packet.awlen);
  $cast(output_conv_h.awsize,waddr_packet.awsize);
  $cast(output_conv_h.awburst,waddr_packet.awburst); 
  $cast(output_conv_h.awlock,waddr_packet.awlock);
  $cast(output_conv_h.awregion,waddr_packet.awregion);
  $cast(output_conv_h.awcache,waddr_packet.awcache);
  $cast(output_conv_h.awprot,waddr_packet.awprot);
  output_conv_h.awaddr = waddr_packet.awaddr;
  output_conv_h.awqos = waddr_packet.awqos;

  foreach(input_conv_h.wdata[i]) begin
    if(input_conv_h.wdata[i] != 0)begin
      output_conv_h.wdata.push_front(input_conv_h.wdata[i]);
      `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wdata[%0d] =  %0h",i,output_conv_h.wdata[i]),UVM_HIGH);
    end
  end

  foreach(input_conv_h.wdata[i]) begin
    if(input_conv_h.wdata[i] != 0)begin
      output_conv_h.wstrb.push_front(input_conv_h.wstrb[i]);
      `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wstrb[%0d] =  %0d",i,output_conv_h.wstrb[i]),UVM_HIGH);
    end
  end

  output_conv_h.wlast = input_conv_h.wlast;
  output_conv_h.wuser = input_conv_h.wuser;
  $cast(output_conv_h.bid,input_conv_h.bid);
  $cast(output_conv_h.bresp,input_conv_h.bresp);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting =  %s",output_conv_h.sprint()),UVM_HIGH);

endfunction : to_write_addr_data_class

//--------------------------------------------------------------------------------------------
// Function: to_write_addr_data_resp_class
// Converting struct data items into seq_item transactions
//
// Parameters:
// name - axi5_master_tx, axi5_write_transfer_char_s
//--------------------------------------------------------------------------------------------
function void axi5_master_seq_item_converter::to_write_addr_data_resp_class(input axi5_master_tx waddr_data_packet, input axi5_write_transfer_char_s input_conv_h, output axi5_master_tx output_conv_h);
  output_conv_h = new();

  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("----------------------------------------------------------------------"),UVM_HIGH);
 

  output_conv_h.tx_type = WRITE; 

  $cast(output_conv_h.awid,waddr_data_packet.awid); 
  $cast(output_conv_h.awlen,waddr_data_packet.awlen);
  $cast(output_conv_h.awsize,waddr_data_packet.awsize);
  $cast(output_conv_h.awburst,waddr_data_packet.awburst); 
  $cast(output_conv_h.awlock,waddr_data_packet.awlock);
  $cast(output_conv_h.awregion,waddr_data_packet.awregion);
  $cast(output_conv_h.awcache,waddr_data_packet.awcache);
  $cast(output_conv_h.awprot,waddr_data_packet.awprot);
  output_conv_h.awaddr = waddr_data_packet.awaddr;
  output_conv_h.awqos = waddr_data_packet.awqos;

  foreach(waddr_data_packet.wdata[i]) begin
    if(waddr_data_packet.wdata[i] != 0)begin
      output_conv_h.wdata.push_back(waddr_data_packet.wdata[i]);
      `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wdata[%0d] =  %0h",i,output_conv_h.wdata[i]),UVM_HIGH);
    end
  end

  foreach(waddr_data_packet.wdata[i]) begin
    if(waddr_data_packet.wdata[i] != 0)begin
      output_conv_h.wstrb.push_back(waddr_data_packet.wstrb[i]);
      `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting wstrb[%0d] =  %0d",i,output_conv_h.wstrb[i]),UVM_HIGH);
    end
  end

  output_conv_h.wlast = waddr_data_packet.wlast;
  output_conv_h.wuser = waddr_data_packet.wuser;
  $cast(output_conv_h.bid,input_conv_h.bid);
  $cast(output_conv_h.bresp,input_conv_h.bresp);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting =  %s",output_conv_h.sprint()),UVM_HIGH);

endfunction : to_write_addr_data_resp_class

//--------------------------------------------------------------------------------------------
// Function: to_read_addr_data_class
// Converting struct data items into seq_item transactions
//
// Parameters:
// name - axi5_master_tx, axi5_read_transfer_char_s
//--------------------------------------------------------------------------------------------
function void axi5_master_seq_item_converter::to_read_addr_data_class(input axi5_master_tx raddr_packet, input axi5_read_transfer_char_s input_conv_h, output axi5_master_tx output_conv_h);

  output_conv_h = new();

  $cast(output_conv_h.arid,raddr_packet.arid);
  $cast(output_conv_h.arlen,raddr_packet.arlen);
  $cast(output_conv_h.arsize,raddr_packet.arsize);
  $cast(output_conv_h.arburst,raddr_packet.arburst);
  $cast(output_conv_h.arlock,raddr_packet.arlock);
  $cast(output_conv_h.arcache,raddr_packet.arcache);
  $cast(output_conv_h.arprot,raddr_packet.arprot);
  output_conv_h.araddr = raddr_packet.araddr;
  output_conv_h.arqos = raddr_packet.arqos;
  $cast(output_conv_h.rid,input_conv_h.rid);

  for(int i=0;i<raddr_packet.arlen+1;i++)begin
        output_conv_h.rdata[i] = input_conv_h.rdata[i];
    `uvm_info("axi5_master_seq_item_conv_class",$sformatf("combined read data packet after reading rdata= %0p",output_conv_h.rdata[i]),UVM_FULL);
    end
  
  $cast(output_conv_h.rresp,input_conv_h.rresp);
  
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("After converting read_addr_data_packet =  %s",output_conv_h.sprint()),UVM_HIGH);
  `uvm_info("axi5_master_seq_item_conv_class",$sformatf("----------------------------------------------------------------------"),UVM_HIGH);

endfunction : to_read_addr_data_class


//--------------------------------------------------------------------------------------------
// Function: do_print method
// Print method can be added to display the data members values
//--------------------------------------------------------------------------------------------
function void axi5_master_seq_item_converter::do_print(uvm_printer printer);

  axi5_write_transfer_char_s axi5_w_st;
  axi5_read_transfer_char_s axi5_r_st;
  super.do_print(printer);
  printer.print_field("awid",axi5_w_st.awid,$bits(axi5_w_st.awid),UVM_DEC);
  printer.print_field("awlen",axi5_w_st.awlen,$bits(axi5_w_st.awlen),UVM_DEC);
  printer.print_field("awsize",axi5_w_st.awsize,$bits(axi5_w_st.awsize),UVM_BIN);
  printer.print_field("awburst",axi5_w_st.awburst,$bits(axi5_w_st.awburst),UVM_BIN);
  printer.print_field("awlock",axi5_w_st.awlock,$bits(axi5_w_st.awlock),UVM_BIN);
  printer.print_field("awregion",axi5_w_st.awregion,$bits(axi5_w_st.awregion),UVM_BIN);
  printer.print_field("awcache",axi5_w_st.awcache,$bits(axi5_w_st.awcache),UVM_BIN);
  printer.print_field("awprot",axi5_w_st.awprot,$bits(axi5_w_st.awprot),UVM_DEC);
  printer.print_field("bid",axi5_w_st.bid,$bits(axi5_w_st.bid),UVM_DEC);
  foreach(axi5_w_st.wdata[i]) begin
    printer.print_field($sformatf("wdata[%0d]",i),axi5_w_st.wdata[i],$bits(axi5_w_st.wdata[i]),UVM_HEX);
  end
  foreach(axi5_w_st.wstrb[i]) begin
    printer.print_field($sformatf("wstrb[%0d]",i),axi5_w_st.wstrb[i],$bits(axi5_w_st.wstrb[i]),UVM_HEX);
  end
 
 printer.print_field("arid",axi5_r_st.arid,$bits(axi5_r_st.arid),UVM_DEC);
 printer.print_field("arlen",axi5_r_st.arlen,$bits(axi5_r_st.arlen),UVM_DEC);
 printer.print_field("arsize",axi5_r_st.arsize,$bits(axi5_r_st.arsize),UVM_BIN);
 printer.print_field("arburst",axi5_r_st.arburst,$bits(axi5_r_st.arburst),UVM_BIN);
 printer.print_field("arlock",axi5_r_st.arlock,$bits(axi5_r_st.arlock),UVM_BIN);
 printer.print_field("arcache",axi5_r_st.arcache,$bits(axi5_r_st.arcache),UVM_BIN);
 printer.print_field("arprot",axi5_r_st.arprot,$bits(axi5_r_st.arprot),UVM_DEC);
 printer.print_field("rresp",axi5_r_st.rresp,$bits(axi5_r_st.rresp),UVM_DEC);
 foreach(axi5_r_st.rdata[i]) begin
   printer.print_field($sformatf("rdata[%0d]",i),axi5_r_st.rdata[i],$bits(axi5_r_st.rdata[i]),UVM_HEX);
 end
endfunction : do_print

`endif
