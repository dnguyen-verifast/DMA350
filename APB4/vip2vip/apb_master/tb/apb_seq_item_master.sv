class apb_seq_item_master
    #(parameter DATA_WIDTH = 32,
      parameter ADDR_WIDTH = 32,
      parameter SLAVE_COUNT = 1,
      parameter STRB_WIDTH = DATA_WIDTH/8)
    extends uvm_sequence_item;
    rand bit [ADDR_WIDTH-1:0]   paddr;
    logic [SLAVE_COUNT-1:0]  psel;
    logic                    penable;
    rand bit [2:0]              pprot;
    rand bit                    pwrite;
    rand bit [DATA_WIDTH-1:0]   pwdata;
    rand bit [STRB_WIDTH-1:0]   pstrb;
    rand bit                    pwakeup;
    rand bit                    pdebug;

    logic                    pready;
    logic                    pslverr;
    logic [DATA_WIDTH-1:0]   prdata;
		`uvm_object_param_utils_begin(apb_seq_item_master #(DATA_WIDTH, ADDR_WIDTH, SLAVE_COUNT))
      `uvm_field_int(paddr,UVM_DEFAULT);
      `uvm_field_int(psel,UVM_DEFAULT);
      `uvm_field_int(penable,UVM_DEFAULT);
      `uvm_field_int(pprot,UVM_DEFAULT);
      `uvm_field_int(pwrite,UVM_DEFAULT);
      `uvm_field_int(pwdata,UVM_DEFAULT);
      `uvm_field_int(pstrb,UVM_DEFAULT);
      `uvm_field_int(pwakeup,UVM_DEFAULT);
      `uvm_field_int(pdebug,UVM_DEFAULT);
      `uvm_field_int(pready,UVM_DEFAULT);
      `uvm_field_int(pslverr,UVM_DEFAULT);
      `uvm_field_int(prdata,UVM_DEFAULT)
		`uvm_object_utils_end
    //bit i_prdata;
    function new(string name="apb_seq_item_master");
        super.new(name);
    endfunction
    constraint c_addr {
        paddr[1:0] == 2'b00;
    }
    constraint c_data {pwdata > 8'd16; }
    // APB4: individual byte-lane update not supported -> pstrb is all-0 or all-1
    constraint c_strb {pstrb inside {'0, '1};}

endclass
