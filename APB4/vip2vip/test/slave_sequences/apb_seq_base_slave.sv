class apb_seq_base_slave extends uvm_sequence #(apb_seq_item_slave);
    `uvm_object_utils(apb_seq_base_slave)

    function new(string name="apb_seq_base_slave");
        super.new(name);
    endfunction
endclass
