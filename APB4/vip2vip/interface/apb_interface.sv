interface apb_interface
    #(parameter DATA_WIDTH = 32,
      parameter ADDR_WIDTH = 32,
      parameter SLAVE_COUNT = 1,
      parameter STRB_WIDTH = DATA_WIDTH/8)
    (input bit clk, input bit rstn);

    // ---------------- APB4 request signals (Requester -> Completer) ----------------
    logic [ADDR_WIDTH-1:0]   paddr;    // Address bus
    logic [SLAVE_COUNT-1:0]  psel;     // Select
    logic                    penable;  // Enable (access phase)
    logic [2:0]              pprot;    // Protection type (normal/priv/secure, data/instr)
    logic                    pwrite;   // Direction: 1=write, 0=read
    logic [DATA_WIDTH-1:0]   pwdata;   // Write data
    logic [STRB_WIDTH-1:0]   pstrb;    // Write strobes (byte lanes to update)
    logic                    pwakeup;  // Pending APB4 activity indicator
    logic                    pdebug;   // Sideband: debugger access, valid with psel

    // ---------------- APB4 response signals (Completer -> Requester) ----------------
    logic                    pready;   // Ready (extend transfer)
    logic                    pslverr;  // Transfer failure
    logic [DATA_WIDTH-1:0]   prdata;   // Read data
endinterface
