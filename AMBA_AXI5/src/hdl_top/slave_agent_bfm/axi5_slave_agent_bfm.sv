`ifndef AXI5_SLAVE_AGENT_BFM_INCLUDED_
`define AXI5_SLAVE_AGENT_BFM_INCLUDED_

//--------------------------------------------------------------------------------------------
// Module:AXI5 Slave Agent BFM
// This module is used as the configuration class for slave agent bfm and its components
//--------------------------------------------------------------------------------------------
module axi5_slave_agent_bfm #(parameter int SLAVE_ID = 0)(axi5_if intf);

  //-------------------------------------------------------
  // Package : Importing Uvm Pakckage and Test Package
  //-------------------------------------------------------
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  //-------------------------------------------------------
  // AXI5 Slave Driver bfm instantiation
  //-------------------------------------------------------
  axi5_slave_driver_bfm axi5_slave_drv_bfm_h (.aclk     (intf.aclk)     , 
                                              .aresetn  (intf.aresetn)  ,
                                              .awid     (intf.awid)     ,           
                                              .awaddr   (intf.awaddr)   ,  
                                              .awlen    (intf.awlen)    ,   
                                              .awsize   (intf.awsize)   ,  
                                              .awburst  (intf.awburst)  , 
                                              .awlock   (intf.awlock)   ,  
                                              .awcache  (intf.awcache)  , 
                                              .awprot   (intf.awprot)   ,
                                              .awqos    (intf.awqos)    ,
                                              .awregion (intf.awregion) ,
                                              .awakeup     (intf.awakeup)     ,
                                              .awdomain    (intf.awdomain)    ,
                                              .awinner     (intf.awinner)     ,
                                              .awchid      (intf.awchid)      ,
                                              .awchidvalid (intf.awchidvalid) ,
                                              .awvalid  (intf.awvalid)  ,
                                              .awready  (intf.awready)  ,
                                                                            
                                              .wdata    (intf.wdata)    ,   
                                              .wstrb    (intf.wstrb)    ,   
                                              .wlast    (intf.wlast)    ,   
                                              .wuser    (intf.wuser)    ,   
                                              .wvalid   (intf.wvalid)   ,  
                                              .wready   (intf.wready)   ,  
                                                              
                                              .bid      (intf.bid)      ,    
                                              .bresp    (intf.bresp)    ,   
                                              .buser    (intf.buser)    ,   
                                              .bvalid   (intf.bvalid)   ,  
                                              .bready   (intf.bready)   ,  
                                                                            
                                              .arid     (intf.arid)     ,    
                                              .araddr   (intf.araddr)   ,  
                                              .arlen    (intf.arlen)    ,   
                                              .arsize   (intf.arsize)   ,  
                                              .arburst  (intf.arburst)  , 
                                              .arlock   (intf.arlock)   ,  
                                              .arcache  (intf.arcache)  , 
                                              .arprot   (intf.arprot)   ,  
                                              .arqos    (intf.arqos)    ,   
                                              .arregion (intf.arregion) ,
                                              .aruser   (intf.aruser)   ,
                                              .ardomain    (intf.ardomain)    ,
                                              .arinner     (intf.arinner)     ,
                                              .archid      (intf.archid)      ,
                                              .archidvalid (intf.archidvalid) ,
                                              .arcmdlink   (intf.arcmdlink)   ,
                                              .arvalid  (intf.arvalid)  ,
                                              .arready  (intf.arready)  ,

                                              .rid      (intf.rid)      ,
                                              .rdata    (intf.rdata)    ,
                                              .rresp    (intf.rresp)    ,
                                              .rlast    (intf.rlast)    ,
                                              .ruser    (intf.ruser)    ,
                                              .rpoison  (intf.rpoison)  ,
                                              .rvalid   (intf.rvalid)   ,
                                              .rready   (intf.rready)
                                              );
  
  //-------------------------------------------------------
  // AXI5 Slave monitor  bfm instantiation
  //-------------------------------------------------------
  axi5_slave_monitor_bfm axi5_slave_mon_bfm_h (.aclk(intf.aclk), 
                                               .aresetn(intf.aresetn),
                                               .awid     (intf.awid)     ,           
                                               .awaddr   (intf.awaddr)   ,  
                                               .awlen    (intf.awlen)    ,   
                                               .awsize   (intf.awsize)   ,  
                                               .awburst  (intf.awburst)  , 
                                               .awlock   (intf.awlock)   ,  
                                               .awcache  (intf.awcache)  , 
                                               .awprot   (intf.awprot)   ,  
                                               .awqos    (intf.awqos)    ,
                                               .awregion (intf.awregion) ,
                                               .awakeup     (intf.awakeup)     ,
                                               .awdomain    (intf.awdomain)    ,
                                               .awinner     (intf.awinner)     ,
                                               .awchid      (intf.awchid)      ,
                                               .awchidvalid (intf.awchidvalid) ,
                                               .awvalid  (intf.awvalid)  ,
                                               .awready  (intf.awready)  ,
                                                                             
                                               .wdata    (intf.wdata)    ,   
                                               .wstrb    (intf.wstrb)    ,   
                                               .wlast    (intf.wlast)    ,   
                                               .wuser    (intf.wuser)    ,   
                                               .wvalid   (intf.wvalid)   ,  
                                               .wready   (intf.wready)   ,  
                                                               
                                               .bid      (intf.bid)      ,    
                                               .bresp    (intf.bresp)    ,   
                                               .buser    (intf.buser)    ,   
                                               .bvalid   (intf.bvalid)   ,  
                                               .bready   (intf.bready)   ,  
                                                                             
                                               .arid     (intf.arid)     ,    
                                               .araddr   (intf.araddr)   ,  
                                               .arlen    (intf.arlen)    ,   
                                               .arsize   (intf.arsize)   ,  
                                               .arburst  (intf.arburst)  , 
                                               .arlock   (intf.arlock)   ,  
                                               .arcache  (intf.arcache)  , 
                                               .arprot   (intf.arprot)   ,  
                                               .arqos    (intf.arqos)    ,   
                                               .arregion (intf.arregion) ,
                                               .aruser   (intf.aruser)   ,
                                               .ardomain    (intf.ardomain)    ,
                                               .arinner     (intf.arinner)     ,
                                               .archid      (intf.archid)      ,
                                               .archidvalid (intf.archidvalid) ,
                                               .arcmdlink   (intf.arcmdlink)   ,
                                               .arvalid  (intf.arvalid)  ,
                                               .arready  (intf.arready)  ,

                                               .rid      (intf.rid)      ,
                                               .rdata    (intf.rdata)    ,
                                               .rresp    (intf.rresp)    ,
                                               .rlast    (intf.rlast)    ,
                                               .ruser    (intf.ruser)    ,
                                               .rpoison  (intf.rpoison)  ,
                                               .rvalid   (intf.rvalid)   ,
                                               .rready   (intf.rready)
                                               );

  bind axi5_slave_driver_bfm slave_assertions S_A (.aclk(aclk),
                                                   .aresetn(aresetn),
                                                   .awid(awid),
                                                   .awaddr(awaddr),
                                                   .awlen(awlen),
                                                   .awsize(awsize),
                                                   .awburst(awburst),
                                                   .awlock(awlock),
                                                   .awcache(awcache),
                                                   .awprot(awprot),
                                                   .awqos(awqos),
                                                   .awregion(awregion),
                                                   .awvalid(awvalid),
                                                   .awready(awready),
                                                   .wdata(intf.wdata),
                                                   .wstrb(intf.wstrb),
                                                   .wlast(intf.wlast),
                                                   .wuser(intf.wuser),
                                                   .wvalid(intf.wvalid),
                                                   .wready(intf.wready),
                                                   .bid(bid),
                                                   .buser(buser),
                                                   .bvalid(bvalid),
                                                   .bready(bready),
                                                   .bresp(bresp),
                                                   .arid(arid),
                                                   .araddr(araddr),  
                                                   .arlen(arlen),   
                                                   .arsize(arsize), 
                                                   .arburst(arburst), 
                                                   .arlock(arlock),  
                                                   .arcache(arcache), 
                                                   .arprot(arprot),
                                                   .arqos(arqos),   
                                                   .arregion(arregion), 
                                                   .aruser(aruser),  
                                                   .arvalid(arvalid), 
                                                   .arready(arready),
                                                   .rid(rid),
                                                   .rdata(rdata),
                                                   .rresp(rresp),
                                                   .rlast(rlast),
                                                   .ruser(ruser),
                                                   .rvalid(rvalid),
                                                   .rready(rready)
                                                  );

  //-------------------------------------------------------
  // Setting the virtual handle of BMFs into config_db
  //-------------------------------------------------------
  initial begin
    uvm_config_db#(virtual axi5_slave_driver_bfm)::set(null,"*", "axi5_slave_driver_bfm", axi5_slave_drv_bfm_h); 
    uvm_config_db#(virtual axi5_slave_monitor_bfm)::set(null,"*", "axi5_slave_monitor_bfm", axi5_slave_mon_bfm_h);
  end

  initial begin
    `uvm_info("axi5 slave agent bfm",$sformatf("AXI5 SLAVE AGENT BFM"),UVM_LOW);
  end
   
endmodule : axi5_slave_agent_bfm

`endif

