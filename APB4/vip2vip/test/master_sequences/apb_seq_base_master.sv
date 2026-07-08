class apb_seq_base_master extends uvm_sequence #(apb_seq_item_master);
    `uvm_object_utils(apb_seq_base_master)
    function new(string name="apb_seq_base_master");
        super.new(name);
    endfunction
endclass
