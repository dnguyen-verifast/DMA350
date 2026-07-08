class apb_monitor_master extends uvm_monitor;
    `uvm_component_utils(apb_monitor_master)
    uvm_analysis_port #(apb_seq_item_master #())  mon_port_m;
    virtual apb_interface apb_if;
    function new(string name ="apb_monitor_master", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_port_m  = new("mon_port_m", this);
        if (!uvm_config_db#(virtual apb_interface)::get(this,"","apb_if",apb_if))
            `uvm_fatal("MON", "Cannot get apb_if.")
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_seq_item_master #() tr;
        super.run_phase(phase);

        forever begin
            @(posedge apb_if.clk);
            while (apb_if.psel == 0) begin
                @(posedge apb_if.clk);
            end
            tr = apb_seq_item_master#()::type_id::create("tr");
            tr.paddr  = apb_if.paddr;
            tr.pwrite = apb_if.pwrite;
            tr.pwdata = apb_if.pwdata;
            tr.pstrb = apb_if.pstrb;
            tr.pprot = apb_if.pprot;
            tr.pwakeup = apb_if.pwakeup;
            tr.pdebug = apb_if.pdebug;
            tr.psel = apb_if.psel;
            tr.penable = apb_if.penable;
            do
               @(posedge apb_if.clk);
            while(!(apb_if.penable && apb_if.pready));
            if (!tr.pwrite) tr.prdata = apb_if.prdata;
                tr.pslverr = apb_if.pslverr;
            mon_port_m.write(tr);
            `uvm_info("MON_MASTER", $sformatf("Captured: Addr=%h Data=%h Write=%b slverr=%b ", tr.paddr, (tr.pwrite ? tr.pwdata : tr.prdata), tr.pwrite, tr.pslverr), UVM_MEDIUM)
            end
    endtask
endclass
