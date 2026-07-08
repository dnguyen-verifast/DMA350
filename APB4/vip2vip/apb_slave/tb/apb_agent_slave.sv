class apb_agent_slave extends uvm_agent;
    `uvm_component_utils(apb_agent_slave)

    uvm_analysis_port #(apb_seq_item_slave #())  mon_port_l;
    apb_driver_slave    apb_dr_l;
    apb_monitor_slave   apb_mon_l;
    apb_sequencer_slave apb_sequencer_slave_h;

    function new(string name ="apb_agent_slave", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_port_l  = new("mon_port_l", this);
        apb_dr_l    = apb_driver_slave   ::type_id::create("apb_dr_l", this);
        apb_mon_l   = apb_monitor_slave  ::type_id::create("apb_mon_l", this);
        apb_sequencer_slave_h = apb_sequencer_slave::type_id::create("apb_sequencer_slave_h", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        apb_dr_l.seq_item_port.connect(apb_sequencer_slave_h.seq_item_export);
        apb_mon_l.mon_port_l.connect(mon_port_l);
    endfunction
endclass
