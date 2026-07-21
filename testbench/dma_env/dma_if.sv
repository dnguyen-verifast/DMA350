//=============================================================================
// dma_if.sv
//-----------------------------------------------------------------------------
// Interface TONG HOP toan bo dan tin hieu bien cua DMA-350 (Table A-1 .. A-11),
// gom mot cho de cac COMPONENT KIEM TRA (vd cmd_trigger_checker) soi nhieu
// interface cung luc ma khong phai giu 7-8 vif rieng le.
//
// Day la interface THU DONG (monitor-only): tb_top `assign` tin hieu vao day tu
// chinh cac net ma DUT dang dung. KHONG lai nguoc ve DUT.
//
// Vi sao can: mot so check mang tinh LIEN-INTERFACE, vi du "khong duoc phat AR
// du lieu truoc khi handshake trigger-in xong" -> phai nhin CA trigger (A-7),
// CA AXI5 (A-5/A-6) va CA status (A-10) trong cung mot thoi diem lay mau.
//
// Luu y ve INDEX:
//   * ch_*      : theo CHANNEL   (0..NUM_CHANNELS-1)
//   * trig_in_* : theo CONG <TI> (0..NUM_TRIGGER_IN-1)  <-- KHONG phai channel
//   Anh xa channel -> cong trigger nam o CH_SRCTRIGINCFG.SEL (xem
//   dma_golden_intent.srctrig_sel). Dung nham index la loi thuong gap.
//=============================================================================
`ifndef DMA_IF_SV
`define DMA_IF_SV
`timescale 1ns/1ps

interface dma_if #(
    parameter int ADDR_WIDTH      = 32,
    parameter int DATA_WIDTH      = 32,
    parameter int ID_WIDTH        = 4,
    parameter int NUM_CHANNELS    = 8,
    parameter int NUM_TRIGGER_IN  = 4,
    parameter int NUM_TRIGGER_OUT = 4,
    parameter int GPO_WIDTH       = 4
) (
    input logic clk,
    input logic resetn
);

  localparam int STRB_WIDTH = DATA_WIDTH/8;

  // ---- A-1 clock enable ----
  logic                       aclken_m0, aclken_m1, pclken;

  // ---- A-2 Q-Channel / A-3 P-Channel ----
  logic                       clk_qreqn, clk_qacceptn, clk_qdeny, clk_qactive;
  logic                       preq, paccept, pdeny;
  logic [3:0]                 pstate;

  // ---- A-4 APB4 ----
  logic                       psel, penable, pwrite, pready, pslverr;
  logic [2:0]                 pprot;
  logic [12:0]                paddr;
  logic [31:0]                pwdata, prdata;
  logic [3:0]                 pstrb;
  logic                       pwakeup, pdebug;

  // ---- A-5 AXI5 M0 ----
  logic                       awvalid_m0, awready_m0;
  logic [ADDR_WIDTH-1:0]      awaddr_m0;
  logic [ID_WIDTH-1:0]        awid_m0;
  logic [7:0]                 awlen_m0;
  logic [2:0]                 awsize_m0;
  logic [1:0]                 awburst_m0;
  logic                       arvalid_m0, arready_m0, arcmdlink_m0;
  logic [ADDR_WIDTH-1:0]      araddr_m0;
  logic [ID_WIDTH-1:0]        arid_m0;
  logic [7:0]                 arlen_m0;
  logic [2:0]                 arsize_m0;
  logic [1:0]                 arburst_m0;
  logic                       archidvalid_m0, awchidvalid_m0;
  logic [7:0]                 archid_m0, awchid_m0;   // rong hon DUT de chua moi CHID_WIDTH
  logic                       wvalid_m0, wready_m0, wlast_m0;
  logic [DATA_WIDTH-1:0]      wdata_m0;
  logic [STRB_WIDTH-1:0]      wstrb_m0;
  logic                       rvalid_m0, rready_m0, rlast_m0;
  logic [DATA_WIDTH-1:0]      rdata_m0;
  logic [ID_WIDTH-1:0]        rid_m0;
  logic [1:0]                 rresp_m0;
  logic                       bvalid_m0, bready_m0;
  logic [ID_WIDTH-1:0]        bid_m0;
  logic [1:0]                 bresp_m0;

  // ---- A-6 AXI5 M1 ----
  logic                       awvalid_m1, awready_m1;
  logic [ADDR_WIDTH-1:0]      awaddr_m1;
  logic [ID_WIDTH-1:0]        awid_m1;
  logic [7:0]                 awlen_m1;
  logic [2:0]                 awsize_m1;
  logic [1:0]                 awburst_m1;
  logic                       arvalid_m1, arready_m1, arcmdlink_m1;
  logic [ADDR_WIDTH-1:0]      araddr_m1;
  logic [ID_WIDTH-1:0]        arid_m1;
  logic [7:0]                 arlen_m1;
  logic [2:0]                 arsize_m1;
  logic [1:0]                 arburst_m1;
  logic                       archidvalid_m1, awchidvalid_m1;
  logic [7:0]                 archid_m1, awchid_m1;
  logic                       wvalid_m1, wready_m1, wlast_m1;
  logic [DATA_WIDTH-1:0]      wdata_m1;
  logic [STRB_WIDTH-1:0]      wstrb_m1;
  logic                       rvalid_m1, rready_m1, rlast_m1;
  logic [DATA_WIDTH-1:0]      rdata_m1;
  logic [ID_WIDTH-1:0]        rid_m1;
  logic [1:0]                 rresp_m1;
  logic                       bvalid_m1, bready_m1;
  logic [ID_WIDTH-1:0]        bid_m1;
  logic [1:0]                 bresp_m1;

  // ---- A-7 Trigger (index theo CONG <TI>/<TO>) ----
  logic [NUM_TRIGGER_IN-1:0]   trig_in_req,  trig_in_ack;
  logic [2*NUM_TRIGGER_IN-1:0] trig_in_req_type, trig_in_ack_type;
  logic [NUM_TRIGGER_OUT-1:0]  trig_out_req, trig_out_ack;

  // ---- A-8 IRQ ----
  logic [NUM_CHANNELS-1:0]    irq_channel;
  logic                       irq_comb_nonsec, irq_comb_sec, irq_sec_viol_err;

  // ---- A-9 Stream (flatten theo channel) ----
  logic [NUM_CHANNELS-1:0]              str_out_tvalid, str_out_tready, str_out_tlast;
  logic [NUM_CHANNELS*DATA_WIDTH-1:0]   str_out_tdata;
  logic [NUM_CHANNELS*STRB_WIDTH-1:0]   str_out_tstrb;
  logic [NUM_CHANNELS-1:0]              str_in_tvalid, str_in_tready, str_in_tlast;
  logic [NUM_CHANNELS*DATA_WIDTH-1:0]   str_in_tdata;
  logic [NUM_CHANNELS*STRB_WIDTH-1:0]   str_in_tstrb;
  logic [NUM_CHANNELS-1:0]              str_in_flush;

  // ---- A-10 Status / Control (index theo CHANNEL) ----
  logic [NUM_CHANNELS*GPO_WIDTH-1:0] gpo_ch;
  logic                       allch_stop_req_nonsec,  allch_stop_ack_nonsec;
  logic                       allch_pause_req_nonsec, allch_pause_ack_nonsec;
  logic                       allch_stop_req_sec,     allch_stop_ack_sec;
  logic                       allch_pause_req_sec,    allch_pause_ack_sec;
  logic                       halt_req, restart_req, halted;
  logic [NUM_CHANNELS-1:0]    ch_enabled, ch_err, ch_stopped, ch_paused,
                              ch_priv, ch_nonsec;

  // ---- A-11 Config / boot ----
  logic                       boot_en;
  logic [ADDR_WIDTH-1:2]      boot_addr;
  logic [7:0]                 boot_memattr;
  logic [1:0]                 boot_shareattr;

  //---------------------------------------------------------------------------
  // Clocking block cho component kiem tra (sample-only).
  // Khong dat mang unpacked vao clocking block (mot so simulator tu choi) - o
  // day tat ca deu la vector packed nen an toan.
  //---------------------------------------------------------------------------
  clocking mon_cb @(posedge clk);
    default input #1step;
    input psel, penable, pwrite, paddr, pwdata, pstrb, pready, pslverr, prdata;
    input awvalid_m0, awready_m0, awaddr_m0, awid_m0, awlen_m0, awsize_m0, awburst_m0;
    input arvalid_m0, arready_m0, araddr_m0, arid_m0, arlen_m0, arsize_m0, arburst_m0;
    input arcmdlink_m0, archid_m0, archidvalid_m0;
    input wvalid_m0, wready_m0, wlast_m0, rvalid_m0, rready_m0, rlast_m0;
    input awvalid_m1, awready_m1, awaddr_m1, awid_m1;
    input arvalid_m1, arready_m1, araddr_m1, arid_m1, arcmdlink_m1;
    input archid_m1, archidvalid_m1;
    input trig_in_req, trig_in_ack, trig_in_req_type, trig_in_ack_type;
    input trig_out_req, trig_out_ack;
    input ch_enabled, ch_err, ch_stopped, ch_paused;
    input irq_channel;
  endclocking

  modport mon (clocking mon_cb, input clk, input resetn);

endinterface : dma_if

`endif // DMA_IF_SV
