class apb_test_ualigned_access extends apb_base_test;
    `uvm_component_utils(apb_test_ualigned_access)

    apb_seq_master_ualigned_access apb_seq_master_ualigned_access_h;
    apb_seq_slave_ualigned_access apb_seq_slave_ualigned_access_h;

    function new(string name="apb_test_ualigned_access", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        apb_seq_master_ualigned_access_h = apb_seq_master_ualigned_access::type_id::create("apb_seq_master_ualigned_access_h");
        apb_seq_slave_ualigned_access_h = apb_seq_slave_ualigned_access::type_id::create("apb_seq_slave_ualigned_access_h");

    endfunction

    task run_phase(uvm_phase phase);

        `uvm_info(get_type_name(),"apb_test_ualigned_access",UVM_LOW);

        phase.raise_objection(this);

        fork 
            begin
                apb_seq_master_ualigned_access_h.start(env.agent_m.apb_sequencer_master_h);
            end
            begin
                apb_seq_slave_ualigned_access_h.start(env.agent_l.apb_sequencer_slave_h);
            end
        join_any
        #100ns;
     phase.drop_objection(this);

    endtask

endclass

