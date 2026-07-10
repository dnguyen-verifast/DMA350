//==============================================================================
// dma350_tb_top.sv  -  Top-level testbench cho CoreLink DMA-350 (UVM)
//------------------------------------------------------------------------------
// Gan DUT that: RTL_DMA_350/dma350_top.sv
//
//  * CLOCK/RESET : do CRLP agent SINH RA (crlp_driver lai crlp_if.clk/resetn,
//    auto_start_clock=1). Moi interface khac + DUT deu an clock nay.
//  * AXI5 M0/M1  : DUT la AXI manager -> VIP axi5_slave (2 agent). VIP dung
//    kien truc BFM hdl_top: o day instantiate TRUC TIEP driver/monitor BFM
//    (KHONG dung wrapper axi5_slave_agent_bfm vi wrapper set config_db key
//    (null,"*") - 2 instance se de len nhau). Key duoc set theo SCOPE tung
//    agent: axi5_agt_slv0_h (M0) / axi5_agent_slv1_h (M1).
//  * AXI5_M1_PRESENT=1 : theo RTL (wr_is_m1), READ di M0, WRITE di M1.
//  * boot_fetch_started : DUT khong co chan rieng -> dan xuat tu
//    arvalid&arready&arcmdlink tren M0 (theo huong dan trong boot_if.sv).
//  * hdl_root    : goc HDL path cho RAL backdoor = "dma350_tb_top.u_dut"
//    (set qua config_db string "hdl_root", reg_env dung khi build RAL).
//==============================================================================
`timescale 1ns/1ps

module dma350_tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import dma350_test_pkg::*;

  //---------------------------------------------------------------------------
  // Tham so build (PHAI khop NUM_CH/SECEXT trong dma350_base_test)
  //---------------------------------------------------------------------------
  localparam int ADDR_W  = 32;
  localparam int DATA_W  = 32;
  localparam int ID_W    = 4;
  localparam int NUM_CH  = 8;
  localparam int GPO_W   = 4;
  localparam int STRB_W  = DATA_W/8;

  //---------------------------------------------------------------------------
  // CRLP : nguon clock/reset cua ca testbench (driver cua agent lai clk/resetn)
  //---------------------------------------------------------------------------
  crlp_if crlp_if_i ();

  wire tb_clk    = crlp_if_i.clk;
  wire tb_resetn = crlp_if_i.resetn;

  //---------------------------------------------------------------------------
  // Interfaces (deu an clock tu CRLP)
  //---------------------------------------------------------------------------
  axi_stream_if #(.DATA_WIDTH(DATA_W)) axis_in_if  (.ACLK(tb_clk), .ARESETn(tb_resetn));
  axi_stream_if #(.DATA_WIDTH(DATA_W)) axis_out_if (.ACLK(tb_clk), .ARESETn(tb_resetn));

  boot_if       #(.ADDR_WIDTH(ADDR_W)) boot_if_i (.clk(tb_clk), .resetn(tb_resetn));
  dma_irq_if    #(.NUM_CHANNELS(NUM_CH), .SECEXT_PRESENT(1)) irq_if_i (.clk(tb_clk), .resetn(tb_resetn));
  apb_interface #(.DATA_WIDTH(32), .ADDR_WIDTH(32)) apb_if_i (.clk(tb_clk), .rstn(tb_resetn));
  dma350_sc_if  sc_if_i (.clk(tb_clk), .resetn(tb_resetn));

  // AXI5 VIP interface (M0 = read path, M1 = write path khi M1_PRESENT)
  axi5_if axi5_m0_if (.aclk(tb_clk), .aresetn(tb_resetn));
  axi5_if axi5_m1_if (.aclk(tb_clk), .aresetn(tb_resetn));

  //---------------------------------------------------------------------------
  // Day/khop width AXI5: DUT <-> axi5_if (VIP dinh nghia awlen[3:0],
  // awcache[1:0], awchid[3:0] khac DUT) -> wire trung gian + assign
  //---------------------------------------------------------------------------
  wire [7:0] awlen8_m0, arlen8_m0, awlen8_m1, arlen8_m1;
  wire [3:0] awcache4_m0, arcache4_m0, awcache4_m1, arcache4_m1;
  wire       awchid1_m0, archid1_m0, awchid1_m1, archid1_m1;

  assign axi5_m0_if.awlen   = awlen8_m0[3:0];   // VIP gioi han 16 beat (du: RTL BURST_SIZE=16)
  assign axi5_m0_if.arlen   = arlen8_m0[3:0];
  assign axi5_m0_if.awcache = awcache4_m0[1:0];
  assign axi5_m0_if.arcache = arcache4_m0[1:0];
  assign axi5_m0_if.awchid  = {3'b0, awchid1_m0};
  assign axi5_m0_if.archid  = {3'b0, archid1_m0};
  assign axi5_m0_if.awlock  = 2'b00;  
  assign axi5_m0_if.awregion = 4'b0;
  assign axi5_m0_if.awuser  = 1'b0;   
  assign axi5_m0_if.wuser    = 4'b0;
  assign axi5_m0_if.arlock  = 2'b00;  
  assign axi5_m0_if.arregion = 4'b0;
  assign axi5_m0_if.aruser  = 4'b0;

  assign axi5_m1_if.awlen   = awlen8_m1[3:0];
  assign axi5_m1_if.arlen   = arlen8_m1[3:0];
  assign axi5_m1_if.awcache = awcache4_m1[1:0];
  assign axi5_m1_if.arcache = arcache4_m1[1:0];
  assign axi5_m1_if.awchid  = {3'b0, awchid1_m1};
  assign axi5_m1_if.archid  = {3'b0, archid1_m1};
  assign axi5_m1_if.awlock  = 2'b00;  
  assign axi5_m1_if.awregion = 4'b0;
  assign axi5_m1_if.awuser  = 1'b0;   
  assign axi5_m1_if.wuser    = 4'b0;
  assign axi5_m1_if.arlock  = 2'b00;  
  assign axi5_m1_if.arregion = 4'b0;
  assign axi5_m1_if.aruser  = 4'b0;

  //---------------------------------------------------------------------------
  // AXI-Stream flatten buses (DUT flatten theo channel; VIP dung channel 0)
  //---------------------------------------------------------------------------
  wire [NUM_CH-1:0]        str_out_tvalid_w, str_out_tlast_w;
  wire [NUM_CH*DATA_W-1:0] str_out_tdata_w;
  wire [NUM_CH*STRB_W-1:0] str_out_tstrb_w;
  wire [NUM_CH-1:0]        str_in_tready_w, str_in_flush_w;

  // OUT (DMA -> peripheral) : DUT lai TVALID/TDATA..., VIP slave lai TREADY
  assign axis_out_if.TVALID = str_out_tvalid_w[0];
  assign axis_out_if.TDATA  = str_out_tdata_w[DATA_W-1:0];
  assign axis_out_if.TSTRB  = str_out_tstrb_w[STRB_W-1:0];
  assign axis_out_if.TKEEP  = str_out_tstrb_w[STRB_W-1:0];
  assign axis_out_if.TLAST  = str_out_tlast_w[0];
  assign axis_out_if.TID    = '0;
  assign axis_out_if.TDEST  = '0;
  assign axis_out_if.TUSER  = '0;
  assign axis_out_if.TWAKEUP = 1'b1;

  // IN (peripheral -> DMA) : VIP master lai TVALID/TDATA..., DUT lai TREADY
  assign axis_in_if.TREADY = str_in_tready_w[0];

  //---------------------------------------------------------------------------
  // Status/Control GPO : DUT flatten [NUM_CH*GPO_W] -> sc_if.gpo_ch[ch][32]
  //---------------------------------------------------------------------------
  wire [NUM_CH*GPO_W-1:0] gpo_flat_w;
  for (genvar gi = 0; gi < NUM_CH; gi++) begin : g_gpo
    assign sc_if_i.gpo_ch[gi] = {{(32-GPO_W){1'b0}}, gpo_flat_w[gi*GPO_W +: GPO_W]};
  end

  //---------------------------------------------------------------------------
  // boot_fetch_started : dan xuat theo huong dan trong boot_if.sv
  //---------------------------------------------------------------------------
  assign boot_if_i.boot_fetch_started =
      axi5_m0_if.arvalid & axi5_m0_if.arready & axi5_m0_if.arcmdlink;

  //---------------------------------------------------------------------------
  // DUT : dma350_top (RTL_DMA_350). NUM_CHANNELS=8, M1 present, SECEXT=1.
  //---------------------------------------------------------------------------
  dma350_top #(
      .ADDR_WIDTH(ADDR_W), .DATA_WIDTH(DATA_W), .ID_WIDTH(ID_W),
      .CHID_WIDTH(0), .POIS_WIDTH(1), .NUM_CHANNELS(NUM_CH),
      .AXI5_M1_PRESENT(1), .SECEXT_PRESENT(1),
      .NUM_TRIGGER_IN(4), .NUM_TRIGGER_OUT(4), .GPO_WIDTH(GPO_W),
      .FIFO_DEPTH(16), .BURST_SIZE(16), .ISSUING_CAP(8), .AWQ_DEPTH(4)
  ) u_dut (
      // ---- A-1 clock/reset (tu CRLP agent) ----
      .clk(tb_clk), .resetn(tb_resetn),
      .aclken_m0(crlp_if_i.aclken_m0), .aclken_m1(crlp_if_i.aclken_m1),
      .pclken(crlp_if_i.pclken),

      // ---- A-2 Q-Channel ----
      .clk_qreqn(crlp_if_i.clk_qreqn),
      .clk_qacceptn(crlp_if_i.clk_qacceptn),
      .clk_qdeny(crlp_if_i.clk_qdeny),
      .clk_qactive(crlp_if_i.clk_qactive),

      // ---- A-3 P-Channel (crlp_if khong co pactive -> de ho) ----
      .preq(crlp_if_i.preq), .pstate(crlp_if_i.pstate),
      .paccept(crlp_if_i.paccept), .pdeny(crlp_if_i.pdeny), .pactive(),

      // ---- A-4 APB4 ----
      .psel(apb_if_i.psel[0]), .penable(apb_if_i.penable),
      .pprot(apb_if_i.pprot), .pwrite(apb_if_i.pwrite),
      .paddr(apb_if_i.paddr[12:0]), .pwdata(apb_if_i.pwdata),
      .pstrb(apb_if_i.pstrb),
      .pready(apb_if_i.pready), .pslverr(apb_if_i.pslverr),
      .prdata(apb_if_i.prdata),
      .pwakeup(apb_if_i.pwakeup), .pdebug(apb_if_i.pdebug),

      // ---- A-5 AXI5 M0 (read path) ----
      .awakeup_m0(axi5_m0_if.awakeup),
      .awvalid_m0(axi5_m0_if.awvalid), .awready_m0(axi5_m0_if.awready),
      .awaddr_m0(axi5_m0_if.awaddr), .awburst_m0(axi5_m0_if.awburst),
      .awid_m0(axi5_m0_if.awid), .awlen_m0(awlen8_m0),
      .awsize_m0(axi5_m0_if.awsize), .awqos_m0(axi5_m0_if.awqos),
      .awprot_m0(axi5_m0_if.awprot), .awcache_m0(awcache4_m0),
      .awdomain_m0(axi5_m0_if.awdomain), .awinner_m0(axi5_m0_if.awinner),
      .awchid_m0(awchid1_m0), .awchidvalid_m0(axi5_m0_if.awchidvalid),
      .arvalid_m0(axi5_m0_if.arvalid), .arready_m0(axi5_m0_if.arready),
      .araddr_m0(axi5_m0_if.araddr), .arburst_m0(axi5_m0_if.arburst),
      .arid_m0(axi5_m0_if.arid), .arlen_m0(arlen8_m0),
      .arsize_m0(axi5_m0_if.arsize), .arqos_m0(axi5_m0_if.arqos),
      .arprot_m0(axi5_m0_if.arprot), .arcache_m0(arcache4_m0),
      .ardomain_m0(axi5_m0_if.ardomain), .arinner_m0(axi5_m0_if.arinner),
      .archid_m0(archid1_m0), .archidvalid_m0(axi5_m0_if.archidvalid),
      .arcmdlink_m0(axi5_m0_if.arcmdlink),
      .wvalid_m0(axi5_m0_if.wvalid), .wready_m0(axi5_m0_if.wready),
      .wlast_m0(axi5_m0_if.wlast), .wstrb_m0(axi5_m0_if.wstrb),
      .wdata_m0(axi5_m0_if.wdata),
      .rvalid_m0(axi5_m0_if.rvalid), .rready_m0(axi5_m0_if.rready),
      .rid_m0(axi5_m0_if.rid), .rlast_m0(axi5_m0_if.rlast),
      .rdata_m0(axi5_m0_if.rdata), .rpoison_m0(axi5_m0_if.rpoison),
      .rresp_m0(axi5_m0_if.rresp),
      .bvalid_m0(axi5_m0_if.bvalid), .bready_m0(axi5_m0_if.bready),
      .bid_m0(axi5_m0_if.bid), .bresp_m0(axi5_m0_if.bresp),

      // ---- A-6 AXI5 M1 (write path, M1_PRESENT=1) ----
      .awakeup_m1(axi5_m1_if.awakeup),
      .awvalid_m1(axi5_m1_if.awvalid), .awready_m1(axi5_m1_if.awready),
      .awaddr_m1(axi5_m1_if.awaddr), .awburst_m1(axi5_m1_if.awburst),
      .awid_m1(axi5_m1_if.awid), .awlen_m1(awlen8_m1),
      .awsize_m1(axi5_m1_if.awsize), .awqos_m1(axi5_m1_if.awqos),
      .awprot_m1(axi5_m1_if.awprot), .awcache_m1(awcache4_m1),
      .awdomain_m1(axi5_m1_if.awdomain), .awinner_m1(axi5_m1_if.awinner),
      .awchid_m1(awchid1_m1), .awchidvalid_m1(axi5_m1_if.awchidvalid),
      .arvalid_m1(axi5_m1_if.arvalid), .arready_m1(axi5_m1_if.arready),
      .araddr_m1(axi5_m1_if.araddr), .arburst_m1(axi5_m1_if.arburst),
      .arid_m1(axi5_m1_if.arid), .arlen_m1(arlen8_m1),
      .arsize_m1(axi5_m1_if.arsize), .arqos_m1(axi5_m1_if.arqos),
      .arprot_m1(axi5_m1_if.arprot), .arcache_m1(arcache4_m1),
      .ardomain_m1(axi5_m1_if.ardomain), .arinner_m1(axi5_m1_if.arinner),
      .archid_m1(archid1_m1), .archidvalid_m1(axi5_m1_if.archidvalid),
      .arcmdlink_m1(axi5_m1_if.arcmdlink),
      .wvalid_m1(axi5_m1_if.wvalid), .wready_m1(axi5_m1_if.wready),
      .wlast_m1(axi5_m1_if.wlast), .wstrb_m1(axi5_m1_if.wstrb),
      .wdata_m1(axi5_m1_if.wdata),
      .rvalid_m1(axi5_m1_if.rvalid), .rready_m1(axi5_m1_if.rready),
      .rid_m1(axi5_m1_if.rid), .rlast_m1(axi5_m1_if.rlast),
      .rdata_m1(axi5_m1_if.rdata), .rpoison_m1(axi5_m1_if.rpoison),
      .rresp_m1(axi5_m1_if.rresp),
      .bvalid_m1(axi5_m1_if.bvalid), .bready_m1(axi5_m1_if.bready),
      .bid_m1(axi5_m1_if.bid), .bresp_m1(axi5_m1_if.bresp),

      // ---- A-7 Trigger : chua co VIP trigger -> tie-off idle ----
      .trig_in_req(4'b0), .trig_in_req_type(8'b0),
      .trig_in_ack(), .trig_in_ack_type(),
      .trig_out_req(), .trig_out_ack(4'b0),

      // ---- A-8 IRQ ----
      .irq_channel(irq_if_i.irq_channel),
      .irq_comb_nonsec(irq_if_i.irq_comb_nonsec),
      .irq_comb_sec(irq_if_i.irq_comb_sec),
      .irq_sec_viol_err(irq_if_i.irq_sec_viol_err),

      // ---- A-9 Stream (channel 0 <-> AXIS VIP; channel khac idle) ----
      .str_out_tvalid(str_out_tvalid_w),
      .str_out_tready({{(NUM_CH-1){1'b0}}, axis_out_if.TREADY}),
      .str_out_tdata(str_out_tdata_w), .str_out_tstrb(str_out_tstrb_w),
      .str_out_tlast(str_out_tlast_w),
      .str_in_tvalid({{(NUM_CH-1){1'b0}}, axis_in_if.TVALID}),
      .str_in_tready(str_in_tready_w),
      .str_in_tdata({{((NUM_CH-1)*DATA_W){1'b0}}, axis_in_if.TDATA}),
      .str_in_tstrb({{((NUM_CH-1)*STRB_W){1'b0}}, axis_in_if.TSTRB}),
      .str_in_tlast({{(NUM_CH-1){1'b0}}, axis_in_if.TLAST}),
      .str_in_flush(str_in_flush_w),

      // ---- A-10 Status/Control (VIP driver lai req; DUT tra ack/status) ----
      .gpo_ch(gpo_flat_w),
      .allch_stop_req_nonsec(sc_if_i.allch_stop_req_nonsec),
      .allch_stop_ack_nonsec(sc_if_i.allch_stop_ack_nonsec),
      .allch_pause_req_nonsec(sc_if_i.allch_pause_req_nonsec),
      .allch_pause_ack_nonsec(sc_if_i.allch_pause_ack_nonsec),
      .allch_stop_req_sec(sc_if_i.allch_stop_req_sec),
      .allch_stop_ack_sec(sc_if_i.allch_stop_ack_sec),
      .allch_pause_req_sec(sc_if_i.allch_pause_req_sec),
      .allch_pause_ack_sec(sc_if_i.allch_pause_ack_sec),
      .halt_req(sc_if_i.halt_req), .restart_req(sc_if_i.restart_req),
      .halted(sc_if_i.halted),
      .ch_enabled(sc_if_i.ch_enabled[NUM_CH-1:0]),
      .ch_err(sc_if_i.ch_err[NUM_CH-1:0]),
      .ch_stopped(sc_if_i.ch_stopped[NUM_CH-1:0]),
      .ch_paused(sc_if_i.ch_paused[NUM_CH-1:0]),
      .ch_priv(sc_if_i.ch_priv[NUM_CH-1:0]),
      .ch_nonsec(sc_if_i.ch_nonsec[NUM_CH-1:0]),

      // ---- A-11 Config/boot (boot VIP lai) ----
      .boot_en(boot_if_i.boot_en), .boot_addr(boot_if_i.boot_addr),
      .boot_memattr(boot_if_i.boot_memattr),
      .boot_shareattr(boot_if_i.boot_shareattr)
  );

  //---------------------------------------------------------------------------
  // AXI5 BFM (driver+monitor) cho M0 va M1 - instantiate truc tiep, KHONG qua
  // wrapper (wrapper set config key global se conflict giua 2 port).
  //---------------------------------------------------------------------------
  axi5_slave_driver_bfm  u_m0_drv_bfm (
      .aclk(tb_clk), .aresetn(tb_resetn),
      .awid(axi5_m0_if.awid), .awaddr(axi5_m0_if.awaddr), .awlen(axi5_m0_if.awlen),
      .awsize(axi5_m0_if.awsize), .awburst(axi5_m0_if.awburst), .awlock(axi5_m0_if.awlock),
      .awcache(axi5_m0_if.awcache), .awprot(axi5_m0_if.awprot), .awqos(axi5_m0_if.awqos),
      .awregion(axi5_m0_if.awregion), .awakeup(axi5_m0_if.awakeup),
      .awdomain(axi5_m0_if.awdomain), .awinner(axi5_m0_if.awinner),
      .awchid(axi5_m0_if.awchid), .awchidvalid(axi5_m0_if.awchidvalid),
      .awvalid(axi5_m0_if.awvalid), .awready(axi5_m0_if.awready),
      .wdata(axi5_m0_if.wdata), .wstrb(axi5_m0_if.wstrb), .wlast(axi5_m0_if.wlast),
      .wuser(axi5_m0_if.wuser), .wvalid(axi5_m0_if.wvalid), .wready(axi5_m0_if.wready),
      .bid(axi5_m0_if.bid), .bresp(axi5_m0_if.bresp), .buser(axi5_m0_if.buser),
      .bvalid(axi5_m0_if.bvalid), .bready(axi5_m0_if.bready),
      .arid(axi5_m0_if.arid), .araddr(axi5_m0_if.araddr), .arlen(axi5_m0_if.arlen),
      .arsize(axi5_m0_if.arsize), .arburst(axi5_m0_if.arburst), .arlock(axi5_m0_if.arlock),
      .arcache(axi5_m0_if.arcache), .arprot(axi5_m0_if.arprot), .arqos(axi5_m0_if.arqos),
      .arregion(axi5_m0_if.arregion), .aruser(axi5_m0_if.aruser),
      .ardomain(axi5_m0_if.ardomain), .arinner(axi5_m0_if.arinner),
      .archid(axi5_m0_if.archid), .archidvalid(axi5_m0_if.archidvalid),
      .arcmdlink(axi5_m0_if.arcmdlink),
      .arvalid(axi5_m0_if.arvalid), .arready(axi5_m0_if.arready),
      .rid(axi5_m0_if.rid), .rdata(axi5_m0_if.rdata), .rresp(axi5_m0_if.rresp),
      .rlast(axi5_m0_if.rlast), .ruser(axi5_m0_if.ruser), .rpoison(axi5_m0_if.rpoison),
      .rvalid(axi5_m0_if.rvalid), .rready(axi5_m0_if.rready)
  );

  axi5_slave_monitor_bfm u_m0_mon_bfm (
      .aclk(tb_clk), .aresetn(tb_resetn),
      .awid(axi5_m0_if.awid), .awaddr(axi5_m0_if.awaddr), .awlen(axi5_m0_if.awlen),
      .awsize(axi5_m0_if.awsize), .awburst(axi5_m0_if.awburst), .awlock(axi5_m0_if.awlock),
      .awcache(axi5_m0_if.awcache), .awprot(axi5_m0_if.awprot), .awqos(axi5_m0_if.awqos),
      .awregion(axi5_m0_if.awregion), .awakeup(axi5_m0_if.awakeup),
      .awdomain(axi5_m0_if.awdomain), .awinner(axi5_m0_if.awinner),
      .awchid(axi5_m0_if.awchid), .awchidvalid(axi5_m0_if.awchidvalid),
      .awvalid(axi5_m0_if.awvalid), .awready(axi5_m0_if.awready),
      .wdata(axi5_m0_if.wdata), .wstrb(axi5_m0_if.wstrb), .wlast(axi5_m0_if.wlast),
      .wuser(axi5_m0_if.wuser), .wvalid(axi5_m0_if.wvalid), .wready(axi5_m0_if.wready),
      .bid(axi5_m0_if.bid), .bresp(axi5_m0_if.bresp), .buser(axi5_m0_if.buser),
      .bvalid(axi5_m0_if.bvalid), .bready(axi5_m0_if.bready),
      .arid(axi5_m0_if.arid), .araddr(axi5_m0_if.araddr), .arlen(axi5_m0_if.arlen),
      .arsize(axi5_m0_if.arsize), .arburst(axi5_m0_if.arburst), .arlock(axi5_m0_if.arlock),
      .arcache(axi5_m0_if.arcache), .arprot(axi5_m0_if.arprot), .arqos(axi5_m0_if.arqos),
      .arregion(axi5_m0_if.arregion), .aruser(axi5_m0_if.aruser),
      .ardomain(axi5_m0_if.ardomain), .arinner(axi5_m0_if.arinner),
      .archid(axi5_m0_if.archid), .archidvalid(axi5_m0_if.archidvalid),
      .arcmdlink(axi5_m0_if.arcmdlink),
      .arvalid(axi5_m0_if.arvalid), .arready(axi5_m0_if.arready),
      .rid(axi5_m0_if.rid), .rdata(axi5_m0_if.rdata), .rresp(axi5_m0_if.rresp),
      .rlast(axi5_m0_if.rlast), .ruser(axi5_m0_if.ruser), .rpoison(axi5_m0_if.rpoison),
      .rvalid(axi5_m0_if.rvalid), .rready(axi5_m0_if.rready)
  );

  axi5_slave_driver_bfm  u_m1_drv_bfm (
      .aclk(tb_clk), .aresetn(tb_resetn),
      .awid(axi5_m1_if.awid), .awaddr(axi5_m1_if.awaddr), .awlen(axi5_m1_if.awlen),
      .awsize(axi5_m1_if.awsize), .awburst(axi5_m1_if.awburst), .awlock(axi5_m1_if.awlock),
      .awcache(axi5_m1_if.awcache), .awprot(axi5_m1_if.awprot), .awqos(axi5_m1_if.awqos),
      .awregion(axi5_m1_if.awregion), .awakeup(axi5_m1_if.awakeup),
      .awdomain(axi5_m1_if.awdomain), .awinner(axi5_m1_if.awinner),
      .awchid(axi5_m1_if.awchid), .awchidvalid(axi5_m1_if.awchidvalid),
      .awvalid(axi5_m1_if.awvalid), .awready(axi5_m1_if.awready),
      .wdata(axi5_m1_if.wdata), .wstrb(axi5_m1_if.wstrb), .wlast(axi5_m1_if.wlast),
      .wuser(axi5_m1_if.wuser), .wvalid(axi5_m1_if.wvalid), .wready(axi5_m1_if.wready),
      .bid(axi5_m1_if.bid), .bresp(axi5_m1_if.bresp), .buser(axi5_m1_if.buser),
      .bvalid(axi5_m1_if.bvalid), .bready(axi5_m1_if.bready),
      .arid(axi5_m1_if.arid), .araddr(axi5_m1_if.araddr), .arlen(axi5_m1_if.arlen),
      .arsize(axi5_m1_if.arsize), .arburst(axi5_m1_if.arburst), .arlock(axi5_m1_if.arlock),
      .arcache(axi5_m1_if.arcache), .arprot(axi5_m1_if.arprot), .arqos(axi5_m1_if.arqos),
      .arregion(axi5_m1_if.arregion), .aruser(axi5_m1_if.aruser),
      .ardomain(axi5_m1_if.ardomain), .arinner(axi5_m1_if.arinner),
      .archid(axi5_m1_if.archid), .archidvalid(axi5_m1_if.archidvalid),
      .arcmdlink(axi5_m1_if.arcmdlink),
      .arvalid(axi5_m1_if.arvalid), .arready(axi5_m1_if.arready),
      .rid(axi5_m1_if.rid), .rdata(axi5_m1_if.rdata), .rresp(axi5_m1_if.rresp),
      .rlast(axi5_m1_if.rlast), .ruser(axi5_m1_if.ruser), .rpoison(axi5_m1_if.rpoison),
      .rvalid(axi5_m1_if.rvalid), .rready(axi5_m1_if.rready)
  );

  axi5_slave_monitor_bfm u_m1_mon_bfm (
      .aclk(tb_clk), .aresetn(tb_resetn),
      .awid(axi5_m1_if.awid), .awaddr(axi5_m1_if.awaddr), .awlen(axi5_m1_if.awlen),
      .awsize(axi5_m1_if.awsize), .awburst(axi5_m1_if.awburst), .awlock(axi5_m1_if.awlock),
      .awcache(axi5_m1_if.awcache), .awprot(axi5_m1_if.awprot), .awqos(axi5_m1_if.awqos),
      .awregion(axi5_m1_if.awregion), .awakeup(axi5_m1_if.awakeup),
      .awdomain(axi5_m1_if.awdomain), .awinner(axi5_m1_if.awinner),
      .awchid(axi5_m1_if.awchid), .awchidvalid(axi5_m1_if.awchidvalid),
      .awvalid(axi5_m1_if.awvalid), .awready(axi5_m1_if.awready),
      .wdata(axi5_m1_if.wdata), .wstrb(axi5_m1_if.wstrb), .wlast(axi5_m1_if.wlast),
      .wuser(axi5_m1_if.wuser), .wvalid(axi5_m1_if.wvalid), .wready(axi5_m1_if.wready),
      .bid(axi5_m1_if.bid), .bresp(axi5_m1_if.bresp), .buser(axi5_m1_if.buser),
      .bvalid(axi5_m1_if.bvalid), .bready(axi5_m1_if.bready),
      .arid(axi5_m1_if.arid), .araddr(axi5_m1_if.araddr), .arlen(axi5_m1_if.arlen),
      .arsize(axi5_m1_if.arsize), .arburst(axi5_m1_if.arburst), .arlock(axi5_m1_if.arlock),
      .arcache(axi5_m1_if.arcache), .arprot(axi5_m1_if.arprot), .arqos(axi5_m1_if.arqos),
      .arregion(axi5_m1_if.arregion), .aruser(axi5_m1_if.aruser),
      .ardomain(axi5_m1_if.ardomain), .arinner(axi5_m1_if.arinner),
      .archid(axi5_m1_if.archid), .archidvalid(axi5_m1_if.archidvalid),
      .arcmdlink(axi5_m1_if.arcmdlink),
      .arvalid(axi5_m1_if.arvalid), .arready(axi5_m1_if.arready),
      .rid(axi5_m1_if.rid), .rdata(axi5_m1_if.rdata), .rresp(axi5_m1_if.rresp),
      .rlast(axi5_m1_if.rlast), .ruser(axi5_m1_if.ruser), .rpoison(axi5_m1_if.rpoison),
      .rvalid(axi5_m1_if.rvalid), .rready(axi5_m1_if.rready)
  );

  //---------------------------------------------------------------------------
  // Config_db + run_test. Set TRUOC run_test trong CUNG initial de dam bao
  // thu tu (khong phu thuoc scheduler giua cac initial block).
  //---------------------------------------------------------------------------
  initial begin
    // ---- virtual interface cho test (key khop dma350_base_test) ----
    uvm_config_db#(virtual axi_stream_if)::set(null, "*", "axis_if_in",  axis_in_if);
    uvm_config_db#(virtual axi_stream_if)::set(null, "*", "axis_if_out", axis_out_if);
    uvm_config_db#(virtual boot_if)::set      (null, "*", "boot_vif",    boot_if_i);
    uvm_config_db#(virtual crlp_if)::set      (null, "*", "crlp_vif",    crlp_if_i);
    uvm_config_db#(virtual dma_irq_if)::set   (null, "*", "irq_vif",     irq_if_i);
    uvm_config_db#(virtual apb_interface)::set(null, "*", "apb_vif",     apb_if_i);
    uvm_config_db#(virtual dma350_sc_if)::set (null, "*", "sc_vif",      sc_if_i);

    // ---- AXI5 BFM: key SCOPE THEO AGENT (M0 -> slv0, M1 -> slv1) ----
    uvm_config_db#(virtual axi5_slave_driver_bfm)::set(null,
        "uvm_test_top.dma350_env_h.axi5_agt_slv0_h*",   "axi5_slave_driver_bfm",  u_m0_drv_bfm);
    uvm_config_db#(virtual axi5_slave_monitor_bfm)::set(null,
        "uvm_test_top.dma350_env_h.axi5_agt_slv0_h*",   "axi5_slave_monitor_bfm", u_m0_mon_bfm);
    uvm_config_db#(virtual axi5_slave_driver_bfm)::set(null,
        "uvm_test_top.dma350_env_h.axi5_agent_slv1_h*", "axi5_slave_driver_bfm",  u_m1_drv_bfm);
    uvm_config_db#(virtual axi5_slave_monitor_bfm)::set(null,
        "uvm_test_top.dma350_env_h.axi5_agent_slv1_h*", "axi5_slave_monitor_bfm", u_m1_mon_bfm);

    // ---- goc HDL path cho RAL backdoor (reg_env doc key nay) ----
    uvm_config_db#(string)::set(null, "*", "hdl_root", "dma350_tb_top.u_dut");

    // ---- tham so build cua DUT: RAL sinh mang DMACH + slice CH_GPOREAD0 theo day ----
    uvm_config_db#(int)::set(null, "*", "num_channels", NUM_CH);
    uvm_config_db#(int)::set(null, "*", "gpo_width",    GPO_W);

    run_test("dma350_base_test");
  end

  //---------------------------------------------------------------------------
  // Waveform (tuy chon)
  //---------------------------------------------------------------------------
  initial begin
    $dumpfile("dma350_tb.vcd");
    $dumpvars(0, dma350_tb_top);
  end

endmodule
