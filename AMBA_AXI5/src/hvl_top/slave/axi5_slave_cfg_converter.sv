`ifndef AXI5_SLAVE_CFG_CONVERTER_INCLUDED_                                                         
`define AXI5_SLAVE_CFG_CONVERTER_INCLUDED_                                                         
                                                                                                  
//--------------------------------------------------------------------------------------------      
// Class: axi5_slave_cfg_converter   
// Description:
// class for converting the transaction items to struct and vice versa                                                              
//--------------------------------------------------------------------------------------------      
class axi5_slave_cfg_converter extends uvm_object;                                                 
`uvm_object_utils(axi5_slave_cfg_converter)                                                      
                                                                                                     
//-------------------------------------------------------                                         
// Externally defined Tasks and Functions                                                         
//-------------------------------------------------------                                         
  extern function new(string name = "axi5_slave_cfg_converter");                                   
  extern static function void from_class(input axi5_slave_agent_config input_conv,output axi5_transfer_cfg_s output_conv);
  extern function void do_print(uvm_printer printer);  

endclass : axi5_slave_cfg_converter                                                                
                                                                                                     
//--------------------------------------------------------------------------------------------      
// Construct: new                                                                                   
// Parameters:                                                                                      
// name - axi5_slave_cfg_converter                                                                  
//--------------------------------------------------------------------------------------------           
function axi5_slave_cfg_converter::new(string name = "axi5_slave_cfg_converter");                 
  super.new(name);                                                                                  
endfunction : new                                                                                   
                                                                                                     
//--------------------------------------------------------------------------------------------           
// function: from_class                                                                             
// converting seq_item transactions into struct data items                                               
//--------------------------------------------------------------------------------------------      
function void axi5_slave_cfg_converter::from_class(input axi5_slave_agent_config input_conv,output axi5_transfer_cfg_s output_conv);
  output_conv.min_address=input_conv.min_address;
  output_conv.max_address=input_conv.max_address;
  output_conv.slave_response_mode = input_conv.slave_response_mode;
endfunction: from_class   
 
 //--------------------------------------------------------------------------------------------      
 // Function: do_print method                                                                        
 // Print method can be added to display the data members values                                     
 //--------------------------------------------------------------------------------------------      
 function void axi5_slave_cfg_converter:: do_print(uvm_printer printer);                            
  axi5_transfer_cfg_s axi5_cfg;                                                                       
  printer.print_field("min_address",axi5_cfg.min_address,$bits(axi5_cfg.min_address),UVM_HEX);
  printer.print_field("max_address",axi5_cfg.max_address,$bits(axi5_cfg.max_address),UVM_HEX);
 endfunction : do_print                                                                              
                                                                                                
`endif
