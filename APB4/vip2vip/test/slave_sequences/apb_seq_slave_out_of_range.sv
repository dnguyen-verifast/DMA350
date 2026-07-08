class apb_seq_slave_out_of_range extends apb_seq_base_slave;
    `uvm_object_utils(apb_seq_slave_out_of_range)

    function new(string name ="apb_seq_slave_out_of_range");
        super.new(name);
    endfunction

    virtual task body();
        apb_seq_item_slave#() item_seq;
        item_seq = apb_seq_item_slave#()::type_id::create("item_seq");

        `uvm_info(get_type_name(),"Inside body of apb_seq_slave_out_of_range",UVM_DEFAULT)

        repeat(2) begin        
            start_item(item_seq);
            assert(item_seq.randomize());
            finish_item(item_seq);
        end
    endtask
endclass
