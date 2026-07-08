class apb_driver_master extends uvm_driver #(apb_seq_item_master);
    `uvm_component_utils(apb_driver_master)

    virtual apb_interface apb_if;
    apb_seq_item_master #()  apb_seq_item_master_h;
    function new(string name ="apb_driver_master", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_interface)::get(this,"","apb_if",apb_if))
            `uvm_fatal("DRV", "Cannot get apb_if.from uvm_config_db")
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        reset_signals();
        wait_reset();
        apb_seq_item_master_h  = apb_seq_item_master #()::type_id::create("apb_seq_item_master_h");
        forever begin
          seq_item_port.get_next_item(apb_seq_item_master_h);
          write_task(apb_seq_item_master_h);
          seq_item_port.item_done(apb_seq_item_master_h);
        end
    endtask

    task reset_signals();
        apb_if.psel    <= '0;
        apb_if.penable <= 1'b0;
        apb_if.pwrite  <= 1'b0;
        apb_if.paddr   <= '0;
        apb_if.pwdata  <= '0;
        apb_if.pprot   <= 3'b000;
        apb_if.pstrb   <= '0;
        apb_if.pwakeup <= 1'b0;
        apb_if.pdebug  <= 1'b0;
    endtask
    task wait_reset();
        `uvm_info("DRV", "Waiting for Reset Release..", UVM_LOW)
        wait(apb_if.rstn == 0);
	`uvm_info("DRV", "Reset Asserted! Now waiting for Release (rstn==1)..", UVM_LOW)
        reset_signals();
        wait(apb_if.rstn == 1);
	`uvm_info("DRV", "Reset Released! Driver is ready.", UVM_LOW)
        @(posedge apb_if.clk);
    endtask
    virtual task write_task(apb_seq_item_master #() tr);
    //setup_phase
		@(posedge apb_if.clk);
        apb_if.paddr   <= tr.paddr;
        apb_if.pwrite  <= tr.pwrite;
        apb_if.pprot   <= tr.pprot;
        apb_if.pwakeup <= tr.pwakeup;
        apb_if.pdebug  <= tr.pdebug;
        apb_if.psel    <= 1'b1;
        apb_if.penable <= 1'b0;
        if (tr.pwrite) begin
          apb_if.pwdata <= tr.pwdata;
          apb_if.pstrb  <= tr.pstrb;   // write strobes valid on writes only
        end else begin
          apb_if.pstrb  <= '0;         // must not be active during a read
        end
    //acess_phase
        @(posedge apb_if.clk);
        apb_if.penable <= 1'b1;
        forever begin
          if (apb_if.pready) break; 
          @(posedge apb_if.clk);
        end

        if (!tr.pwrite) begin
            tr.prdata = apb_if.prdata; 
        end
        tr.pslverr = apb_if.pslverr;
				
        //end_phase
        apb_if.psel    <= '0;
        apb_if.penable <= 1'b0;
    endtask
endclass
