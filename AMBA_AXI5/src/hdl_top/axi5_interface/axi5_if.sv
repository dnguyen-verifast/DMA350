`ifndef AXI5_IF_INCLUDED_
`define AXI5_IF_INCLUDED_

// Import axi5_globals_pkg 
import axi5_globals_pkg::*;

//--------------------------------------------------------------------------------------------
// Interface : axi5_if
// Declaration of pin level signals for axi5 interface
//--------------------------------------------------------------------------------------------
interface axi5_if(input aclk, input aresetn);

  //Write_address_channel
  logic     [3: 0] awid     ;
  logic     [ADDRESS_WIDTH-1: 0] awaddr ;
  logic     [3: 0] awlen     ;
  logic     [2: 0] awsize    ;
  logic     [1: 0] awburst   ;
  logic     [1: 0] awlock    ;
  logic     [1: 0] awcache   ;
  logic     [2: 0] awprot    ;
  logic     [3:0] awqos      ;
  logic     [3:0] awregion   ;
  logic           awuser     ;
  //AXI5 Write Address Channel additional signals
  logic                    awakeup     ; //Pending AXI5 activity indicator
  logic     [1:0]          awdomain    ; //Shareability domain of a write transaction
  logic     [3:0]          awinner     ; //Inner domain cache attributes for writes
  logic  [CHID_WIDTH-1:0]  awchid      ; //SW configurable channel ID indication
  logic                    awchidvalid ; //Validity of the SW configurable channel ID
  logic            awvalid   ;
  logic		         awready   ;
  //Write_data_channel
  logic     [DATA_WIDTH-1: 0] wdata     ;
  logic     [(DATA_WIDTH/8)-1: 0] wstrb ;
  logic            wlast     ;
  logic      [3:0] wuser     ;
  logic            wvalid    ;
 	logic            wready    ;
  //Write Response Channel
  logic     [3: 0] bid       ;
  logic     [1: 0] bresp     ;
  logic     [3: 0] buser     ;
  logic            bvalid    ;
  logic            bready    ;
  //Read Address Channel
  logic     [3: 0] arid     ;
  logic     [ADDRESS_WIDTH-1:0] araddr  ;
  logic     [3:0] arlen      ;
  logic     [2:0] arsize     ;
  logic     [1:0] arburst    ;
  logic     [1:0] arlock     ;
  logic     [1:0] arcache    ;
  logic     [2:0] arprot     ;
  logic     [3:0] arqos      ;
  logic     [3:0] arregion   ;
  logic     [3:0] aruser     ;
  //AXI5 Read Address Channel additional signals
  logic     [1:0]          ardomain    ; //Shareability domain of a read transaction
  logic     [3:0]          arinner     ; //Inner domain cache attributes for reads
  logic  [CHID_WIDTH-1:0]  archid      ; //SW configurable channel ID indication
  logic                    archidvalid ; //Validity of the SW configurable channel ID
  logic                    arcmdlink   ; //Command link read indication
  logic           arvalid    ;
 	logic	          arready    ;
  //Read Data Channel
  logic     [3: 0] rid      ;
  logic     [DATA_WIDTH-1: 0] rdata     ;
  logic     [1:0] rresp      ;
  logic           rlast      ;
  logic     [3:0] ruser      ;
  logic  [POISON_WIDTH-1:0] rpoison   ; //AXI5 read data poison signal
  logic           rvalid     ;
  logic  	        rready     ;
  

endinterface: axi5_if 

`endif
