`ifndef AXI5_SLAVE_MEM_MAP_CFG_INCLUDE_
`define AXI5_SLAVE_MEM_MAP_CFG_INCLUDE_ 
class axi5_slave_mem_map_cfg extends uvm_object;
    `uvm_object_utils(axi5_slave_mem_map_cfg)
    axi5_slave_mem_region_cfg mem_region_cfg[16];
    function new(string name = "axi5_slave_mem_map_cfg");
        super.new(name);
        foreach (mem_region_cfg[i]) begin   
            mem_region_cfg[i] = new();
        end
    endfunction
    function void test_set_mem_region_cfg(region_e region, axi5_slave_mem_region_cfg cfg);
        mem_region_cfg[region] = cfg;
    endfunction

    function axi5_slave_mem_region_cfg slave_get_mem_region_cfg(region_e region);
        return mem_region_cfg[region];  
    endfunction
endclass
`endif
