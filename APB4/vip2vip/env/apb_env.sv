class apb_env extends uvm_env;
    `uvm_component_utils(apb_env)

    apb_agent_master        agent_m;
    apb_agent_slave         agent_l;
    apb_scoreboard          scb;

    function new(string name="apb_env",uvm_component parent=null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent_m = apb_agent_master::type_id::create("agent_m", this);
        agent_l = apb_agent_slave::type_id::create("agent_l",this);
        scb   = apb_scoreboard::type_id::create("scb", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent_m.mon_port_m.connect(scb.master_export);
        agent_l.mon_port_l.connect(scb.slave_export);
    endfunction
endclass
