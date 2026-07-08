`ifndef AXI5_SLAVE_MEMORY_INCLUDED_
`define AXI5_SLAVE_MEMORY_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_slave_agent
// This agent has sequencer, driver_proxy, monitor_proxy for axi5  
//--------------------------------------------------------------------------------------------
class axi5_slave_memory extends uvm_object;
  `uvm_object_utils(axi5_slave_memory)

  axi5_slave_mem_map_cfg mem_map_cfg;

  //Variable : slave_memory
  //Declaration of slave_memory to store the data from master
  protected bit [7:0] slave_memory [longint];
  parameter bit [ADDRESS_WIDTH-1:0] REGION_OFFSET = 32'h0000_4000;

  protected bit [31:0] exclusive_monitor [int];

   //Variable : fifo_memory
  //Variable : fifo_memory
  //Declaration of fifo_memory to store the data from master of type fixed
  protected bit [7:0] fifo_memory [$];

  extern function new(string name = "axi5_slave_memory");
  extern virtual function void init_memory_cfg();
  extern virtual function void init_default_mem_map_cfg();
  extern virtual function void record_read_exclusive (bit [ADDRESS_WIDTH-1:0] address, bit [3:0] id);
  extern virtual function bit check_exclusive_write (bit [ADDRESS_WIDTH-1:0] address, bit [3:0] id);
  extern virtual function void clear_monitor_on_write (bit [ADDRESS_WIDTH-1:0] address); 
  extern virtual function bit [ADDRESS_WIDTH-1:0] get_region_base_addr(bit [ADDRESS_WIDTH-1:0] base_addr, region_e region_id);  
  extern virtual function void mem_write(input bit [ADDRESS_WIDTH-1:0]slave_address, bit [DATA_WIDTH-1:0]data);
  extern virtual function void mem_read (input bit [ADDRESS_WIDTH-1:0]slave_address, output bit [DATA_WIDTH-1:0]data);
  extern virtual function void fifo_write(input bit [DATA_WIDTH-1:0]data);
  extern virtual function void fifo_read (output bit [DATA_WIDTH-1:0]data);
  extern virtual function int check_access_permission( bit [ADDRESS_WIDTH-1:0] base_addr,
                                                       region_e region_id, 
                                                       prot_e prot,
                                                       lock_e lock,
                                                       bit is_write);
  extern virtual function bit is_slave_addr_exists(input bit [ADDRESS_WIDTH-1 :0]slave_address);

endclass : axi5_slave_memory

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi5_slave_agent_config
//--------------------------------------------------------------------------------------------
function axi5_slave_memory::new(string name = "axi5_slave_memory");
  super.new(name); 
endfunction : new

function void axi5_slave_memory::init_memory_cfg();
  axi5_slave_mem_region_cfg region_cfg;

  if(uvm_config_db#(axi5_slave_mem_map_cfg)::get(null,"*", "mem_map_cfg", mem_map_cfg)) begin
    `uvm_info(get_type_name(), $sformatf("Memory map configuration is set"), UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), $sformatf("Memory map configuration is not set, using default configuration"), UVM_LOW)
    init_default_mem_map_cfg();
  end 
endfunction : init_memory_cfg

function void axi5_slave_memory::init_default_mem_map_cfg();
  
  axi5_slave_mem_region_cfg region_cfg;

  mem_map_cfg = axi5_slave_mem_map_cfg::type_id::create("mem_map_cfg");

  region_cfg = axi5_slave_mem_region_cfg::type_id::create("REGION_WR_NORMAL");
  region_cfg.prot_slave = NORMAL_SECURE_DATA;
  region_cfg.lock_slave = NORMAL_ACCESS;
  region_cfg.data_mode = WRITE_READ_DATA;
  mem_map_cfg.test_set_mem_region_cfg(REGION_WR_NORMAL, region_cfg);
  
  region_cfg = axi5_slave_mem_region_cfg::type_id::create("REGION_WR_SECURE");
  region_cfg.prot_slave = NORMAL_SECURE_DATA;
  region_cfg.lock_slave = NORMAL_ACCESS;
  region_cfg.data_mode = WRITE_READ_DATA;
  mem_map_cfg.test_set_mem_region_cfg(REGION_WR_SECURE, region_cfg);

  region_cfg = axi5_slave_mem_region_cfg::type_id::create("REGION_RD_NORMAL");
  region_cfg.prot_slave = NORMAL_SECURE_DATA;
  region_cfg.lock_slave = NORMAL_ACCESS;
  region_cfg.data_mode = WRITE_READ_DATA;
  mem_map_cfg.test_set_mem_region_cfg(REGION_RD_NORMAL, region_cfg);

  region_cfg = axi5_slave_mem_region_cfg::type_id::create("REGION_RD_SECURE");
  region_cfg.prot_slave =PRIVILEGED_SECURE_DATA;
  region_cfg.lock_slave = NORMAL_ACCESS;
  region_cfg.data_mode = WRITE_READ_DATA;
  mem_map_cfg.test_set_mem_region_cfg(REGION_RD_SECURE, region_cfg);

  region_cfg = axi5_slave_mem_region_cfg::type_id::create("REGION_EXCLUSIVE");
  region_cfg.prot_slave = PRIVILEGED_SECURE_DATA ;
  region_cfg.lock_slave = EXCLUSIVE_ACCESS;
  region_cfg.data_mode = WRITE_READ_DATA;
  mem_map_cfg.test_set_mem_region_cfg(REGION_EXCLUSIVE, region_cfg);


endfunction : init_default_mem_map_cfg


 function bit [ADDRESS_WIDTH-1:0] axi5_slave_memory::get_region_base_addr(bit [ADDRESS_WIDTH -1:0] base_addr, region_e region_id);
  return base_addr + (region_id * REGION_OFFSET);
endfunction : get_region_base_addr



 function void axi5_slave_memory::record_read_exclusive (bit [ADDRESS_WIDTH-1:0] address, bit [3:0] id);
  exclusive_monitor[address] = id;
  `uvm_info("EXCL_MON", $sformatf("Manager ID %0d granted exclusive tracking at Addr 32'h%0h", id, address), UVM_LOW)
endfunction : record_read_exclusive

 function bit axi5_slave_memory::check_exclusive_write (bit [ADDRESS_WIDTH-1:0] address, bit [3:0] id);
  if(exclusive_monitor.exists(address) && exclusive_monitor[address] == id) begin
    exclusive_monitor.delete(id);
    return 1; 
    `uvm_info("EXCL_MON", $sformatf("Manager ID %0d granted exclusive tracking at Addr 32'h%0h", id, address), UVM_HIGH)
  end else begin
    `uvm_warning(get_type_name(), $sformatf("Exclusive write violation at address %h by ID %0d", address, id))
    return 0;
  end
endfunction : check_exclusive_write

 function void axi5_slave_memory::clear_monitor_on_write (bit [ADDRESS_WIDTH-1:0] address);
  bit [3:0] id_queue [$];
  foreach(exclusive_monitor[id]) begin
      if(exclusive_monitor[id] == address) begin
        id_queue.push_back(id);
      end
  end
  foreach(id_queue[i]) begin
    exclusive_monitor.delete(id_queue[i]);
    `uvm_info("EXCL_MON", $sformatf("Clearing exclusive monitor for ID %0d at Addr 32'h%0h due to write operation", id_queue[i], address), UVM_LOW)
  end
endfunction : clear_monitor_on_write


//--------------------------------------------------------------------------------------------
//Task : mem_write
//Used to store the slave data into the slave memory
//Parameter :
//slave_address - bit [ADDRESS_WIDTH-1 :0]
//data          - bit [DATA_WIDTH-1:0]
//--------------------------------------------------------------------------------------------
function void axi5_slave_memory::mem_write(input bit [ADDRESS_WIDTH-1 :0]slave_address, bit [DATA_WIDTH-1:0]data);
  slave_memory[slave_address] = data;
endfunction : mem_write

//--------------------------------------------------------------------------------------------
//Task : mem_read
//Used to store the slave data into the slave memory
//Parameter :
//slave_address - bit [ADDRESS_WIDTH-1 :0]
//data          - bit [DATA_WIDTH-1:0]
//--------------------------------------------------------------------------------------------
function void axi5_slave_memory::mem_read(input bit [ADDRESS_WIDTH-1 :0]slave_address, output bit [DATA_WIDTH-1:0]data);
   if(slave_memory.exists(slave_address)) begin
     data = slave_memory[slave_address];
   end else begin
     `uvm_warning(get_type_name(), $sformatf("Address %h does not exist in slave memory", slave_address))
     data = '0; // Return default value if address does not exist
     return;
   end
endfunction : mem_read

//--------------------------------------------------------------------------------------------
//Task : fifo_write
//Used to store the slave data into the slave memory
//Parameter :
//data          - bit [DATA_WIDTH-1:0]
//--------------------------------------------------------------------------------------------
function void axi5_slave_memory::fifo_write(input bit [DATA_WIDTH-1:0]data);
  fifo_memory.push_front(data);
endfunction : fifo_write

//--------------------------------------------------------------------------------------------
//Task : fifo_read
//Used to store the slave data into the slave memory
//Parameter :
//data          - bit [DATA_WIDTH-1:0]
//--------------------------------------------------------------------------------------------
function void axi5_slave_memory::fifo_read(output bit [DATA_WIDTH-1:0]data);
  data = fifo_memory.pop_back();
endfunction : fifo_read


 function int axi5_slave_memory::check_access_permission( bit [ADDRESS_WIDTH-1:0] base_addr,
                                                       region_e region_id, 
                                                       prot_e prot,
                                                       lock_e lock,
                                                       bit is_write);
  axi5_slave_mem_region_cfg region_cfg;
  region_cfg = mem_map_cfg.slave_get_mem_region_cfg(region_id);
  if(region_cfg == null) begin
    `uvm_warning(get_type_name(), $sformatf("Region ID %0d does not exist in memory map configuration", region_id))
    return 0; // Access denied if region configuration is not found
  end

  if(is_write) begin
    if (region_cfg.data_mode == ONLY_READ_DATA) return 2; 
    if (lock == WRITE_EXCLUSIVE_ACCESS && region_cfg.lock_slave == WRITE_NORMAL_ACCESS) return 2;
    if (region_cfg.prot_slave[1] == 1'b0 && prot[1] == 1'b1) return 2;
    if (region_cfg.prot_slave[0] == 1'b1 && prot[0] == 1'b0) return 2;
  end else begin
    if (region_cfg.data_mode == ONLY_WRITE_DATA) return 2;
    if (lock == READ_EXCLUSIVE_ACCESS && region_cfg.lock_slave == READ_NORMAL_ACCESS) return 2;
    if (region_cfg.prot_slave[1] == 1'b0 && prot[1] == 1'b1) return 2;
    if (region_cfg.prot_slave[0] == 1'b1 && prot[0] == 1'b0) return 2;
  end
  return 0;
endfunction : check_access_permission
//--------------------------------------------------------------------------------------------
//Task : is_slave_addr_exists
//Used to check the address exists are not in the memory
//slave_address - bit [ADDRESS_WIDTH-1 :0]
//--------------------------------------------------------------------------------------------
function bit axi5_slave_memory::is_slave_addr_exists(input bit [ADDRESS_WIDTH-1 :0]slave_address);
  is_slave_addr_exists = slave_memory.exists(slave_address);
endfunction: is_slave_addr_exists

`endif
