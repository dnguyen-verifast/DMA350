class apb_base_test extends uvm_test;
    `uvm_component_utils(apb_base_test)

    apb_env      env;

    function new(string name="apb_base_test",uvm_component parent=null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env      = apb_env::type_id::create("env", this);
    endfunction
	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		`uvm_info(get_type_name(),$sformatf("apb_base_test"),UVM_LOW)
		phase.raise_objection(this);
        #100;
		phase.drop_objection(this);
	endtask
endclass
