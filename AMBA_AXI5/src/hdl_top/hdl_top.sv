`ifndef HDL_TOP_INCLUDED_
`define HDL_TOP_INCLUDED_

//--------------------------------------------------------------------------------------------
// Module      : HDL Top
// Description : Has a interface master and slave agent bfm.
//--------------------------------------------------------------------------------------------

module hdl_top;

  import uvm_pkg::*;
  import axi5_globals_pkg::*;
	import axi5_test_pkg::*;
  `include "uvm_macros.svh"

  //-------------------------------------------------------
  // Clock Reset Initialization
  //-------------------------------------------------------
  bit aclk;
  bit aresetn;

  //-------------------------------------------------------
  // Display statement for HDL_TOP
  //-------------------------------------------------------
  initial begin
    $display("HDL_TOP");
  end

  //-------------------------------------------------------
  // System Clock Generation
  //-------------------------------------------------------
  initial begin
    aclk = 1'b0;
    forever #10 aclk = ~aclk;
  end

  //-------------------------------------------------------
  // System Reset Generation
  // Active low reset
  //-------------------------------------------------------
  initial begin
    aresetn = 1'b1;
    #10 aresetn = 1'b0;

    repeat (1) begin
      @(posedge aclk);
    end
    aresetn = 1'b1;
  end

  // Variable : intf
  // axi5 Interface Instantiation
  axi5_if intf(.aclk(aclk),
               .aresetn(aresetn));

  //-------------------------------------------------------
  // AXI5  No of Master and Slaves Agent Instantiation
  //-------------------------------------------------------
  genvar i;
  generate
    for (i=0; i<NO_OF_MASTERS; i++) begin : axi5_master_agent_bfm
      axi5_master_agent_bfm #(.MASTER_ID(i)) axi5_master_agent_bfm_h(intf);
      defparam axi5_master_agent_bfm[i].axi5_master_agent_bfm_h.MASTER_ID = i;
    end
    for (i=0; i<NO_OF_SLAVES; i++) begin : axi5_slave_agent_bfm
      axi5_slave_agent_bfm #(.SLAVE_ID(i)) axi5_slave_agent_bfm_h(intf);
      defparam axi5_slave_agent_bfm[i].axi5_slave_agent_bfm_h.SLAVE_ID = i;
    end
  endgenerate

	initial begin : START_TEST 
    run_test("axi5_blocking_8b_write_data_test");
  end
  
endmodule : hdl_top

`endif

