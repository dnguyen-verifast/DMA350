class apb_agent_master extends uvm_agent;
    `uvm_component_utils(apb_agent_master)

    uvm_analysis_port #(apb_seq_item_master #())  mon_port_m;
    apb_driver_master    apb_dr_m;
    apb_monitor_master   apb_mon_m;
    apb_sequencer_master apb_sequencer_master_h;

    function new(string name ="apb_agent_master", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_port_m  = new("mon_port_m", this);
        apb_dr_m    = apb_driver_master   ::type_id::create("apb_dr_m", this);
        apb_mon_m   = apb_monitor_master  ::type_id::create("apb_mon_m", this);
        apb_sequencer_master_h = apb_sequencer_master::type_id::create("apb_sequencer_master_h", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        apb_dr_m.seq_item_port.connect(apb_sequencer_master_h.seq_item_export);
        apb_mon_m.mon_port_m.connect(mon_port_m);
    endfunction
endclass
