`uvm_analysis_imp_decl(_master)
`uvm_analysis_imp_decl(_slave)

class apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(apb_scoreboard)

    // Cổng nhận dữ liệu từ Master Monitor và Slave Monitor
    uvm_analysis_imp_master #(apb_seq_item_master, apb_scoreboard) master_export;
    uvm_analysis_imp_slave  #(apb_seq_item_slave, apb_scoreboard) slave_export;

    // FIFO để chứa dữ liệu chờ so sánh
    uvm_tlm_analysis_fifo #(apb_seq_item_master) master_fifo;
    uvm_tlm_analysis_fifo #(apb_seq_item_slave) slave_fifo;

    int total_checked = 0;
    int total_failed  = 0;

    function new(string name="apb_scoreboard", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        master_export = new("master_export", this);
        slave_export  = new("slave_export", this);
        master_fifo   = new("master_fifo", this);
        slave_fifo    = new("slave_fifo", this);
    endfunction

    // Hàm write nhận dữ liệu từ Master
    virtual function void write_master(apb_seq_item_master tr);
        void'(master_fifo.try_put(tr));
    endfunction

    // Hàm write nhận dữ liệu từ Slave 
    virtual function void write_slave(apb_seq_item_slave tr);
        void'(slave_fifo.try_put(tr)); //void' tắt các cảnh báo của trình biên dịch khi try_put là function sẽ trả về giá trị nhưng ta không kiểm tra nó
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_seq_item_master m_tr;
       apb_seq_item_slave s_tr; 
        forever begin
            `uvm_info("SCB","waiting for master....",UVM_MEDIUM)      
          master_fifo.get(m_tr);
          `uvm_info("SCB","waiting for slave....",UVM_MEDIUM)      
            slave_fifo.get(s_tr);
            
            total_checked++;
            compare_data(m_tr, s_tr);
        end
    endtask

    virtual function void compare_data(apb_seq_item_master m_tr, apb_seq_item_slave s_tr);
        bit error = 0;

        // 1. So sánh Địa chỉ
        if (m_tr.paddr !== s_tr.paddr) begin
            `uvm_error("SCB_ADDR_MISMATCH", $sformatf("Addr Mismatch! Master: %0h, Slave: %0h", m_tr.paddr, s_tr.paddr))
            error = 1;
        end

        // 2. So sánh Loại giao dịch (Read/Write)
        if (m_tr.pwrite !== s_tr.pwrite) begin
            `uvm_error("SCB_CMD_MISMATCH", $sformatf("Command Mismatch! Master: %0b, Slave: %0b", m_tr.pwrite, s_tr.pwrite))
            error = 1;
        end

        // 3. So sánh Dữ liệu
        if (m_tr.pwrite == 1'b1) begin // Write operation
            if (m_tr.pwdata !== s_tr.pwdata) begin
                `uvm_error("SCB_DATA_MISMATCH", $sformatf("Write Data Mismatch! Master: %0h, Slave: %0h", m_tr.pwdata, s_tr.pwdata))
                error = 1;
            end
        end else begin // Read operation
            if (m_tr.prdata !== s_tr.prdata) begin
                `uvm_error("SCB_DATA_MISMATCH", $sformatf("Read Data Mismatch! Master: %0h, Slave: %0h", m_tr.prdata, s_tr.prdata))
                error = 1;
            end
        end

        // 4. Kiểm tra trạng thái lỗi từ Slave (nếu cần)
        if (m_tr.pslverr !== s_tr.pslverr) begin
            `uvm_error("SCB_PSLVERR_MISMATCH", "Slave Error signal mismatch!")
            error = 1;
        end

        if (error) total_failed++;
        else `uvm_info("SCB_MATCH", $sformatf("Transaction %0d matched successfully.", total_checked), UVM_HIGH)
        
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (master_fifo.used() != 0 || slave_fifo.used() != 0) begin
            `uvm_error("SCB_UNMATCHED", $sformatf("Dangling transactions! Master FIFO: %0d, Slave FIFO: %0d", 
                                        master_fifo.used(), slave_fifo.used()))
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB_REPORT", $sformatf("\n------------------------------\n TOTAL CHECKED: %0d \n TOTAL FAILED : %0d \n------------------------------", 
                                total_checked, total_failed), UVM_NONE)
    endfunction
endclass
