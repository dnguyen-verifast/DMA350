class apb_driver_slave extends uvm_driver #(apb_seq_item_slave);
    `uvm_component_utils(apb_driver_slave)

    virtual apb_interface apb_if;
    apb_seq_item_slave #()  apb_seq_item_slave_h;
    function new(string name ="apb_driver_slave", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_interface)::get(this,"","apb_if",apb_if))
            `uvm_fatal("DRV", "Cannot get apb_if from uvm_config_db")
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        reset_signals();
        wait_reset();
        apb_seq_item_slave_h  = apb_seq_item_slave #()::type_id::create("apb_seq_item_slave_h");
        forever begin
					@(posedge apb_if.clk iff (apb_if.psel == 1'b1 && apb_if.penable == 1'b0));
          seq_item_port.get_next_item(apb_seq_item_slave_h);
          receive_task(apb_seq_item_slave_h);
          seq_item_port.item_done();
        end
    endtask

    task reset_signals();
        apb_if.prdata  <= 0;
        apb_if.pslverr <= 1'b0;
        apb_if.pready  <= 1'b0;

    endtask
    task wait_reset();
        `uvm_info("DRV_SLAVE", "Waiting for Reset Release...", UVM_LOW)
        wait(apb_if.rstn == 0);
        `uvm_info("DRV_SLAVE", "Reset Asserted! Now waiting for Release (rstn==1)..", UVM_LOW)
        reset_signals();
        wait(apb_if.rstn == 1);
        `uvm_info("DRV_SLAVE", "Reset Released! Driver is ready.", UVM_LOW)
        @(posedge apb_if.clk);
    endtask
    virtual task receive_task(apb_seq_item_slave #() tr);
    //setup phase 	
       // wait(apb_if.psel == 1'b1);
		//acces_phase
        repeat(tr.pdelay) begin
            @(posedge apb_if.clk);
        end
        apb_if.pready <= 1'b1;
        if(apb_if.penable == 1'b0)
            @(posedge apb_if.clk);
        if (apb_if.pwrite) begin // wr
            tr.pwdata = apb_if.pwdata;
            tr.paddr = apb_if.paddr;
            tr.pstrb = apb_if.pstrb;
        end else begin // rd
            if(apb_if.penable && apb_if.psel) begin
                apb_if.prdata <= tr.prdata;
            end
        end
        // capture the remaining APB4 sideband/request signals
        tr.pprot   = apb_if.pprot;
        tr.pwakeup = apb_if.pwakeup;
        tr.pdebug  = apb_if.pdebug;
		//check err
       	if(apb_if.psel && apb_if.penable) begin
					// out-of-range address OR illegal write-strobe pattern -> error response.
					// APB4: individual byte-lane update not supported, pstrb must be all-0 or all-1.
					if(apb_if.paddr >= 32'h1FF00000) begin
           		 apb_if.pslverr <= 1'b1;
						end	else if(apb_if.pwrite && !(apb_if.pstrb == '0 || apb_if.pstrb == '1)) begin
						 apb_if.pslverr <= 1'b1;
						end	else	apb_if.pslverr <= 1'b0;
				end
       	 @(posedge apb_if.clk);
        //end_phase
        apb_if.pready <= 1'b0;
        apb_if.pslverr <= 1'b0;
    endtask
endclass
