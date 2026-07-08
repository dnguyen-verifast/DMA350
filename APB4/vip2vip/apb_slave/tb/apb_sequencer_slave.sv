class apb_sequencer_slave extends uvm_sequencer #(apb_seq_item_slave);
    `uvm_component_utils(apb_sequencer_slave)

    function new(string name="apb_sequencer_slave", uvm_component parent=null);
        super.new(name,parent);
    endfunction
endclass
