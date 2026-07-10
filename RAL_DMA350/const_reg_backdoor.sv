//==============================================================================
// const_reg_backdoor.sv  -  Backdoor cho thanh ghi hang so (localparam trong RTL)
//------------------------------------------------------------------------------
// Mot so thanh ghi ID/build-config khong co storage trong RTL: gia tri cua chung
// la localparam duoc mux thang ra prdata (vd CH_IIDR_VAL trong dma350_ch_regs).
// uvm_hdl_read() KHONG doc duoc localparam qua VPI tren Questa/VCS, nen khong the
// dung add_hdl_path_slice().
//
// Lop nay tra ve hang so khi peek(), va bao UVM_NOT_OK khi poke() (ghi vao hang
// so la loi cua testbench, phai lo ra chu khong im lang).
//==============================================================================
class const_reg_backdoor extends uvm_reg_backdoor;

    local uvm_reg_data_t m_val;

    function new(string name = "const_reg_backdoor", uvm_reg_data_t val = 0);
        super.new(name);
        m_val = val;
    endfunction

    virtual function void read_func(uvm_reg_item rw);
        if (rw.value.size() == 0) rw.value = new[1];
        rw.value[0] = m_val;
        rw.status   = UVM_IS_OK;
    endfunction

    virtual task write(uvm_reg_item rw);
        rw.status = UVM_NOT_OK;
        `uvm_error("CONST_BKDR", $sformatf(
            "poke() vao thanh ghi hang so '%s': RTL khong co storage de ghi",
            (rw.element == null) ? get_name() : rw.element.get_full_name()))
    endtask

endclass
