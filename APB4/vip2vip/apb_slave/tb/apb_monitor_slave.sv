class apb_monitor_slave extends uvm_monitor;
    `uvm_component_utils(apb_monitor_slave)

    virtual apb_interface apb_if;
    uvm_analysis_port #(apb_seq_item_slave #())  mon_port_l;

    function new(string name ="apb_monitor_slave", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_port_l  = new("mon_port_l", this);
        if (!uvm_config_db#(virtual apb_interface)::get(this,"","apb_if",apb_if))
            `uvm_fatal("MON", "Cannot get apb_if")
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_seq_item_slave #() tr;
        super.run_phase(phase);
        forever begin
            @(posedge apb_if.clk);
            while (apb_if.psel == 0) begin
                @(posedge apb_if.clk);
            end
            tr = apb_seq_item_slave#()::type_id::create("tr");
            tr.paddr  = apb_if.paddr;
            tr.pwrite = apb_if.pwrite;
            tr.pwdata = apb_if.pwdata;
            tr.pstrb = apb_if.pstrb;
            tr.pprot = apb_if.pprot;
            tr.pwakeup = apb_if.pwakeup;
            tr.pdebug = apb_if.pdebug;
            tr.psel = apb_if.psel;
            tr.penable = apb_if.penable;
            do begin
                @(posedge apb_if.clk);
            end while(!(apb_if.penable && apb_if.pready));
            if (!tr.pwrite) tr.prdata = apb_if.prdata;
            tr.pslverr = apb_if.pslverr;
            tr.pready = apb_if.pready;
            mon_port_l.write(tr);
            `uvm_info("MON_SLAVE", $sformatf("Captured: Addr=%h Data=%h Write=%b", tr.paddr, (tr.pwrite ? tr.pwdata : tr.prdata), tr.pwrite), UVM_MEDIUM)	
            end
    endtask
endclass
