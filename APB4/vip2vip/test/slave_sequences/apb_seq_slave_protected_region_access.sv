class apb_seq_slave_protected_region_access extends apb_seq_base_slave;
    `uvm_object_utils(apb_seq_slave_protected_region_access)

    function new(string name ="apb_seq_slave_protected_region_access");
        super.new(name);
    endfunction

    virtual task body();
        apb_seq_item_slave#() item_seq;
        item_seq = apb_seq_item_slave#()::type_id::create("item_seq");

        `uvm_info(get_type_name(),"Inside body of apb_seq_slave_protected_region_access",UVM_DEFAULT)

        repeat(2) begin        
            start_item(item_seq);
            assert(item_seq.randomize());
            finish_item(item_seq);
        end
    endtask
endclass
