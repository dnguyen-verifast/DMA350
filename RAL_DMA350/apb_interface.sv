interface busapb_if (input pclk);
    logic           psel;
    logic           penable;
    logic [2:0]     pprot;
    logic           pwrite;
    logic [32-1:0]  paddr;
    logic [32-1:0]  pwdata;
    logic [3:0]     pstrb;
    logic           pready;
    logic           pslverr;
    logic [32-1:0]  prdata;
    logic           pwakeup;
    logic           pdebug;

endinterface
