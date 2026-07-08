`ifndef AXI5_SLAVE_MEM_REGION_CFG_INCLUDE_
`define AXI5_SLAVE_MEM_REGION_CFG_INCLUDE_ 
class axi5_slave_mem_region_cfg extends uvm_object;
    `uvm_object_utils(axi5_slave_mem_region_cfg)
    prot_e prot_slave;
    lock_e lock_slave;
    write_read_data_mode_e data_mode;
    function new(string name = "axi5_slave_mem_region_cfg");
        super.new(name);
        prot_slave = NORMAL_SECURE_DATA;
        lock_slave = NORMAL_ACCESS;
        data_mode = WRITE_READ_DATA;
    endfunction
endclass
`endif
