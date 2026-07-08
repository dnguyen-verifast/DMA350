class apb_seq_item_slave
    #(parameter DATA_WIDTH = 32,
      parameter ADDR_WIDTH = 32,
      parameter SLAVE_COUNT = 1,
      parameter STRB_WIDTH = DATA_WIDTH/8)
    extends uvm_sequence_item;
    logic [ADDR_WIDTH-1:0]   paddr;
    logic [SLAVE_COUNT-1:0]  psel;
    logic                    penable;
    logic [2:0]              pprot;
    logic                    pwrite;
    logic [DATA_WIDTH-1:0]   pwdata;
    logic [STRB_WIDTH-1:0]   pstrb;
    logic                    pwakeup;
    logic                    pdebug;

    logic                    pready;
    rand bit                    pslverr;
    rand bit [DATA_WIDTH-1:0]   prdata;
    rand bit [1:0]            pdelay;
		`uvm_object_param_utils_begin(apb_seq_item_slave #(DATA_WIDTH, ADDR_WIDTH, SLAVE_COUNT))
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
    function new(string name="apb_seq_item_slave");
        super.new(name);
    endfunction
    constraint r_data {prdata [DATA_WIDTH-1:DATA_WIDTH-8] > 8'd250; };
    constraint slverr {pslverr dist {0:=90, 1:=10};};
    constraint delay_h {pdelay dist {0:/50, 1:/25, 2:/15, 3:/10};};
endclass
