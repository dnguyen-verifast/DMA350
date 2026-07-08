class apb_seq_master_protected_region_access extends apb_seq_base_master;
    `uvm_object_utils(apb_seq_master_protected_region_access)

    function new(string name ="apb_seq_master_protected_region_access");
        super.new(name);
    endfunction

    virtual task body();
        apb_seq_item_master item_seq_m;
        bit [31:0] queue_addr [$];
        bit [31:0] addr;
        `uvm_info(get_type_name(),"Inside body of apb_seq_master_test",UVM_DEFAULT)
		repeat(10) begin
            item_seq_m = apb_seq_item_master#()::type_id::create("item_seq_m");
        	start_item(item_seq_m);
       		assert(item_seq_m.randomize() with {pwrite == 1'b1; apb_if.paddr >= (2^16*(3/4)); apb_if.paddr <= 32'h10000; });
            queue_addr.push_back(item_seq_m.paddr);
        	finish_item(item_seq_m);
		end
    endtask
endclass