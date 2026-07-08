class apb_sequencer_master extends uvm_sequencer #(apb_seq_item_master);
    `uvm_component_utils(apb_sequencer_master)

    function new(string name="apb_sequencer_master", uvm_component parent=null);
        super.new(name,parent);
    endfunction
endclass
