class reg2apb_adapter extends uvm_reg_adapter;
    `uvm_object_utils(reg2apb_adapter)
    function new(string name="reg2apb_adapter");
        super.new(name);
        supports_byte_enable = 1;  // enable byte lane cause apb have pstrb
        provides_responses   = 0;   
    endfunction
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        apb_seq_item tr = apb_seq_item::type_id::create("tr");
        tr.pwrite = (rw.kind == UVM_WRITE) ? 1:0;
        tr.paddr  = rw.addr;
        tr.pwdata = rw.data;
        tr.pstrb  = rw.byte_en;
        return tr;
    endfunction
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        apb_seq_item tr;
        if(!$cast(tr,bus_item)) begin
            `uvm_fatal("DMA_350_ADAPTER", "bus_item not match apb_seq_item")
            return;
        end
        rw.kind = tr.pwrite ? UVM_WRITE : UVM_READ;
        rw.addr = tr.paddr;
        rw.data = tr.prdata;
        rw.status = tr.pslverr ? UVM_NOT_OK : UVM_IS_OK;
    endfunction
endclass